package postgres

import (
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/pos/backend/internal/domain"
)

type RoutineRepo struct {
	db *DB
}

func NewRoutineRepository(db *DB) *RoutineRepo {
	return &RoutineRepo{db: db}
}

func scanRoutineItem(scanner interface{ Scan(...any) error }) (*domain.RoutineItem, error) {
	var item domain.RoutineItem
	var metaBytes []byte
	var schedDate time.Time
	var completedAt *time.Time

	err := scanner.Scan(
		&item.ID,
		&item.TemplateID,
		&item.Title,
		&item.Category,
		&item.TimeWindow,
		&schedDate,
		&item.Status,
		&completedAt,
		&metaBytes,
		&item.UpdatedAt,
		&item.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	item.ScheduledDate = schedDate.Format("2006-01-02")
	if completedAt != nil {
		item.CompletedAt = *completedAt
	}
	if len(metaBytes) > 0 {
		_ = json.Unmarshal(metaBytes, &item.Metadata)
	}
	if item.Metadata == nil {
		item.Metadata = make(map[string]any)
	}
	return &item, nil
}

func (r *RoutineRepo) GetByID(ctx context.Context, id string) (*domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE id = $1
	`
	row := r.db.Pool.QueryRow(ctx, query, id)
	item, err := scanRoutineItem(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get routine item by ID: %w", err)
	}
	return item, nil
}

func (r *RoutineRepo) ListByDate(ctx context.Context, date string) ([]domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE scheduled_date = $1
		ORDER BY created_at ASC
	`
	return r.queryList(ctx, query, date)
}

func (r *RoutineRepo) ListSince(ctx context.Context, since time.Time) ([]domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE updated_at > $1
		ORDER BY updated_at ASC
	`
	return r.queryList(ctx, query, since)
}

func (r *RoutineRepo) queryList(ctx context.Context, query string, args ...any) ([]domain.RoutineItem, error) {
	rows, err := r.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list routines: %w", err)
	}
	defer rows.Close()

	var items []domain.RoutineItem
	for rows.Next() {
		item, err := scanRoutineItem(rows)
		if err != nil {
			return nil, fmt.Errorf("failed to scan routine item: %w", err)
		}
		items = append(items, *item)
	}
	return items, nil
}

func (r *RoutineRepo) UpdateStatus(ctx context.Context, id string, status domain.ItemStatus, completedAt *time.Time) error {
	query := `
		UPDATE routine_items
		SET status = $1, completed_at = $2, updated_at = NOW()
		WHERE id = $3
	`
	res, err := r.db.Pool.Exec(ctx, query, status, completedAt, id)
	if err != nil {
		return fmt.Errorf("failed to update routine status: %w", err)
	}
	if res.RowsAffected() == 0 {
		return errors.New("routine item not found")
	}
	return nil
}

func (r *RoutineRepo) ResetPendingToMissed(ctx context.Context, beforeDate string) (int64, error) {
	query := `
		UPDATE routine_items
		SET status = 'MISSED', updated_at = NOW()
		WHERE scheduled_date < $1 AND status = 'PENDING'
	`
	res, err := r.db.Pool.Exec(ctx, query, beforeDate)
	if err != nil {
		return 0, fmt.Errorf("failed to reset pending items to missed: %w", err)
	}
	return res.RowsAffected(), nil
}
