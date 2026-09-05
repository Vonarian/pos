package postgres

import (
	"context"
	"encoding/json/v2"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/pos/backend/internal/domain"
)

const upsertRoutineQuery = `
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

func prepareRoutineWriteParams(item *domain.RoutineItem, now time.Time) ([]any, error) {
	metaBytes, err := json.Marshal(item.Metadata)
	if err != nil {
		metaBytes = []byte("{}")
	}

	updatedAt := item.UpdatedAt
	if updatedAt.IsZero() {
		updatedAt = now
	}
	createdAt := item.CreatedAt
	if createdAt.IsZero() {
		createdAt = now
	}

	var completedAt any
	if !item.CompletedAt.IsZero() {
		completedAt = item.CompletedAt
	}

	return []any{
		item.ID,
		item.TemplateID,
		item.Title,
		item.Category,
		item.TimeWindow,
		item.ScheduledDate,
		item.Status,
		completedAt,
		metaBytes,
		updatedAt,
		createdAt,
	}, nil
}

func (r *RoutineRepo) Upsert(ctx context.Context, item *domain.RoutineItem) error {
	params, _ := prepareRoutineWriteParams(item, time.Now().UTC())
	_, err := r.db.Pool.Exec(ctx, upsertRoutineQuery, params...)
	if err != nil {
		return fmt.Errorf("failed to upsert routine item: %w", err)
	}
	return nil
}

func (r *RoutineRepo) BatchUpsert(ctx context.Context, items []domain.RoutineItem) error {
	if len(items) == 0 {
		return nil
	}

	batch := &pgx.Batch{}
	now := time.Now().UTC()

	for i := range items {
		params, _ := prepareRoutineWriteParams(&items[i], now)
		batch.Queue(upsertRoutineQuery, params...)
	}

	br := r.db.Pool.SendBatch(ctx, batch)
	defer br.Close()

	for range items {
		if _, err := br.Exec(); err != nil {
			return fmt.Errorf("failed executing batch upsert for routine item: %w", err)
		}
	}

	return br.Close()
}
