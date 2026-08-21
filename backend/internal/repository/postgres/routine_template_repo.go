package postgres

import (
	"context"
	"encoding/json/v2"
	"fmt"
	"time"

	"github.com/pos/backend/internal/domain"
)

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
