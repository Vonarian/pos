package postgres

import (
	"context"
	"encoding/json"
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

func (r *RoutineRepo) GetByID(ctx context.Context, id string) (*domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE id = $1
	`
	row := r.db.Pool.QueryRow(ctx, query, id)

	var item domain.RoutineItem
	var metaBytes []byte
	var schedDate time.Time

	err := row.Scan(
		&item.ID,
		&item.TemplateID,
		&item.Title,
		&item.Category,
		&item.TimeWindow,
		&schedDate,
		&item.Status,
		&item.CompletedAt,
		&metaBytes,
		&item.UpdatedAt,
		&item.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get routine item by ID: %w", err)
	}

	item.ScheduledDate = schedDate.Format("2006-01-02")
	if len(metaBytes) > 0 {
		_ = json.Unmarshal(metaBytes, &item.Metadata)
	}
	if item.Metadata == nil {
		item.Metadata = make(map[string]any)
	}

	return &item, nil
}

func (r *RoutineRepo) ListByDate(ctx context.Context, date string) ([]domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE scheduled_date = $1
		ORDER BY created_at ASC
	`
	rows, err := r.db.Pool.Query(ctx, query, date)
	if err != nil {
		return nil, fmt.Errorf("failed to list routines by date: %w", err)
	}
	defer rows.Close()

	var items []domain.RoutineItem
	for rows.Next() {
		var item domain.RoutineItem
		var metaBytes []byte
		var schedDate time.Time

		err := rows.Scan(
			&item.ID,
			&item.TemplateID,
			&item.Title,
			&item.Category,
			&item.TimeWindow,
			&schedDate,
			&item.Status,
			&item.CompletedAt,
			&metaBytes,
			&item.UpdatedAt,
			&item.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan routine item: %w", err)
		}

		item.ScheduledDate = schedDate.Format("2006-01-02")
		if len(metaBytes) > 0 {
			_ = json.Unmarshal(metaBytes, &item.Metadata)
		}
		if item.Metadata == nil {
			item.Metadata = make(map[string]any)
		}
		items = append(items, item)
	}

	return items, nil
}

func (r *RoutineRepo) ListSince(ctx context.Context, since time.Time) ([]domain.RoutineItem, error) {
	query := `
		SELECT id, template_id, title, category, time_window, scheduled_date,
		       status, completed_at, metadata, updated_at, created_at
		FROM routine_items
		WHERE updated_at > $1
		ORDER BY updated_at ASC
	`
	rows, err := r.db.Pool.Query(ctx, query, since)
	if err != nil {
		return nil, fmt.Errorf("failed to list routines since: %w", err)
	}
	defer rows.Close()

	var items []domain.RoutineItem
	for rows.Next() {
		var item domain.RoutineItem
		var metaBytes []byte
		var schedDate time.Time

		err := rows.Scan(
			&item.ID,
			&item.TemplateID,
			&item.Title,
			&item.Category,
			&item.TimeWindow,
			&schedDate,
			&item.Status,
			&item.CompletedAt,
			&metaBytes,
			&item.UpdatedAt,
			&item.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan routine item: %w", err)
		}

		item.ScheduledDate = schedDate.Format("2006-01-02")
		if len(metaBytes) > 0 {
			_ = json.Unmarshal(metaBytes, &item.Metadata)
		}
		if item.Metadata == nil {
			item.Metadata = make(map[string]any)
		}
		items = append(items, item)
	}

	return items, nil
}

func (r *RoutineRepo) Upsert(ctx context.Context, item *domain.RoutineItem) error {
	metaBytes, err := json.Marshal(item.Metadata)
	if err != nil {
		metaBytes = []byte("{}")
	}

	now := time.Now().UTC()
	if item.UpdatedAt.IsZero() {
		item.UpdatedAt = now
	}
	if item.CreatedAt.IsZero() {
		item.CreatedAt = now
	}

	query := `
		INSERT INTO routine_items (
			id, template_id, title, category, time_window, scheduled_date,
			status, completed_at, metadata, updated_at, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		ON CONFLICT (id) DO UPDATE SET
			template_id = EXCLUDED.template_id,
			title = EXCLUDED.title,
			category = EXCLUDED.category,
			time_window = EXCLUDED.time_window,
			scheduled_date = EXCLUDED.scheduled_date,
			status = EXCLUDED.status,
			completed_at = EXCLUDED.completed_at,
			metadata = EXCLUDED.metadata,
			updated_at = EXCLUDED.updated_at
	`

	_, err = r.db.Pool.Exec(ctx, query,
		item.ID,
		item.TemplateID,
		item.Title,
		item.Category,
		item.TimeWindow,
		item.ScheduledDate,
		item.Status,
		item.CompletedAt,
		metaBytes,
		item.UpdatedAt,
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to upsert routine item: %w", err)
	}
	return nil
}

func (r *RoutineRepo) BatchUpsert(ctx context.Context, items []domain.RoutineItem) error {
	if len(items) == 0 {
		return nil
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, item := range items {
		metaBytes, _ := json.Marshal(item.Metadata)
		if len(metaBytes) == 0 {
			metaBytes = []byte("{}")
		}
		now := time.Now().UTC()
		if item.UpdatedAt.IsZero() {
			item.UpdatedAt = now
		}
		if item.CreatedAt.IsZero() {
			item.CreatedAt = now
		}

		query := `
			INSERT INTO routine_items (
				id, template_id, title, category, time_window, scheduled_date,
				status, completed_at, metadata, updated_at, created_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (id) DO UPDATE SET
				template_id = EXCLUDED.template_id,
				title = EXCLUDED.title,
				category = EXCLUDED.category,
				time_window = EXCLUDED.time_window,
				scheduled_date = EXCLUDED.scheduled_date,
				status = EXCLUDED.status,
				completed_at = EXCLUDED.completed_at,
				metadata = EXCLUDED.metadata,
				updated_at = EXCLUDED.updated_at
		`
		_, err = tx.Exec(ctx, query,
			item.ID,
			item.TemplateID,
			item.Title,
			item.Category,
			item.TimeWindow,
			item.ScheduledDate,
			item.Status,
			item.CompletedAt,
			metaBytes,
			item.UpdatedAt,
			item.CreatedAt,
		)
		if err != nil {
			return fmt.Errorf("failed to batch upsert item %s: %w", item.ID, err)
		}
	}

	return tx.Commit(ctx)
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

func (r *RoutineRepo) ListActiveTemplates(ctx context.Context) ([]domain.RoutineTemplate, error) {
	query := `
		SELECT id, title, category, time_window, days_of_week, metadata, is_active, created_at
		FROM routine_templates
		WHERE is_active = true
		ORDER BY created_at ASC
	`
	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list active templates: %w", err)
	}
	defer rows.Close()

	var templates []domain.RoutineTemplate
	for rows.Next() {
		var tpl domain.RoutineTemplate
		var daysBytes, metaBytes []byte

		err := rows.Scan(
			&tpl.ID,
			&tpl.Title,
			&tpl.Category,
			&tpl.TimeWindow,
			&daysBytes,
			&metaBytes,
			&tpl.IsActive,
			&tpl.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan routine template: %w", err)
		}

		if len(daysBytes) > 0 {
			_ = json.Unmarshal(daysBytes, &tpl.DaysOfWeek)
		}
		if len(metaBytes) > 0 {
			_ = json.Unmarshal(metaBytes, &tpl.Metadata)
		}
		templates = append(templates, tpl)
	}

	return templates, nil
}

func (r *RoutineRepo) CreateTemplate(ctx context.Context, template *domain.RoutineTemplate) error {
	daysBytes, err := json.Marshal(template.DaysOfWeek)
	if err != nil {
		daysBytes = []byte("[]")
	}
	metaBytes, err := json.Marshal(template.Metadata)
	if err != nil {
		metaBytes = []byte("{}")
	}

	now := time.Now().UTC()
	if template.CreatedAt.IsZero() {
		template.CreatedAt = now
	}

	query := `
		INSERT INTO routine_templates (
			id, title, category, time_window, days_of_week, metadata, is_active, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			category = EXCLUDED.category,
			time_window = EXCLUDED.time_window,
			days_of_week = EXCLUDED.days_of_week,
			metadata = EXCLUDED.metadata,
			is_active = EXCLUDED.is_active
	`
	_, err = r.db.Pool.Exec(ctx, query,
		template.ID,
		template.Title,
		template.Category,
		template.TimeWindow,
		daysBytes,
		metaBytes,
		template.IsActive,
		template.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to create routine template: %w", err)
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
