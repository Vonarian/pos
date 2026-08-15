package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/pos/backend/internal/domain"
)

type MetricRepo struct {
	db *DB
}

func NewMetricRepository(db *DB) *MetricRepo {
	return &MetricRepo{db: db}
}

func (m *MetricRepo) BatchUpsert(ctx context.Context, points []domain.HealthDataPoint) error {
	if len(points) == 0 {
		return nil
	}

	tx, err := m.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, pt := range points {
		now := time.Now().UTC()
		if pt.SyncedAt.IsZero() {
			pt.SyncedAt = now
		}

		query := `
			INSERT INTO health_metrics (
				id, source, metric, value, unit, start_time, end_time, external_id, synced_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
			ON CONFLICT (external_id) DO UPDATE SET
				source = EXCLUDED.source,
				value = EXCLUDED.value,
				unit = EXCLUDED.unit,
				start_time = EXCLUDED.start_time,
				end_time = EXCLUDED.end_time,
				synced_at = EXCLUDED.synced_at
		`
		if pt.ExternalID == nil || *pt.ExternalID == "" {
			query = `
				INSERT INTO health_metrics (
					id, source, metric, value, unit, start_time, end_time, external_id, synced_at
				) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
				ON CONFLICT (id) DO UPDATE SET
					source = EXCLUDED.source,
					metric = EXCLUDED.metric,
					value = EXCLUDED.value,
					unit = EXCLUDED.unit,
					start_time = EXCLUDED.start_time,
					end_time = EXCLUDED.end_time,
					synced_at = EXCLUDED.synced_at
			`
		}

		_, err = tx.Exec(ctx, query,
			pt.ID,
			pt.Source,
			pt.Metric,
			pt.Value,
			pt.Unit,
			pt.StartTime,
			pt.EndTime,
			pt.ExternalID,
			pt.SyncedAt,
		)
		if err != nil {
			return fmt.Errorf("failed to upsert health metric point %s: %w", pt.ID, err)
		}
	}

	return tx.Commit(ctx)
}

func (m *MetricRepo) ListSince(ctx context.Context, since time.Time) ([]domain.HealthDataPoint, error) {
	query := `
		SELECT id, source, metric, value, unit, start_time, end_time, external_id, synced_at
		FROM health_metrics
		WHERE synced_at > $1
		ORDER BY synced_at ASC
	`
	rows, err := m.db.Pool.Query(ctx, query, since)
	if err != nil {
		return nil, fmt.Errorf("failed to list metrics since: %w", err)
	}
	defer rows.Close()

	var points []domain.HealthDataPoint
	for rows.Next() {
		var pt domain.HealthDataPoint
		err := rows.Scan(
			&pt.ID,
			&pt.Source,
			&pt.Metric,
			&pt.Value,
			&pt.Unit,
			&pt.StartTime,
			&pt.EndTime,
			&pt.ExternalID,
			&pt.SyncedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan health data point: %w", err)
		}
		points = append(points, pt)
	}

	return points, nil
}

func (m *MetricRepo) GetDailySummary(ctx context.Context, date string) (map[domain.MetricType]float64, error) {
	// Group metrics by day start and end
	query := `
		SELECT metric, SUM(value) as total_val
		FROM health_metrics
		WHERE DATE(start_time) = $1
		GROUP BY metric
	`
	rows, err := m.db.Pool.Query(ctx, query, date)
	if err != nil {
		return nil, fmt.Errorf("failed to get daily summary: %w", err)
	}
	defer rows.Close()

	summary := make(map[domain.MetricType]float64)
	for rows.Next() {
		var metric domain.MetricType
		var total float64
		if err := rows.Scan(&metric, &total); err != nil {
			return nil, fmt.Errorf("failed to scan daily summary row: %w", err)
		}
		summary[metric] = total
	}

	return summary, nil
}

func (m *MetricRepo) GetMetricSeries(ctx context.Context, metric domain.MetricType, from, to time.Time) ([]domain.HealthDataPoint, error) {
	query := `
		SELECT id, source, metric, value, unit, start_time, end_time, external_id, synced_at
		FROM health_metrics
		WHERE metric = $1 AND start_time >= $2 AND end_time <= $3
		ORDER BY start_time ASC
	`
	rows, err := m.db.Pool.Query(ctx, query, metric, from, to)
	if err != nil {
		return nil, fmt.Errorf("failed to get metric series: %w", err)
	}
	defer rows.Close()

	var points []domain.HealthDataPoint
	for rows.Next() {
		var pt domain.HealthDataPoint
		err := rows.Scan(
			&pt.ID,
			&pt.Source,
			&pt.Metric,
			&pt.Value,
			&pt.Unit,
			&pt.StartTime,
			&pt.EndTime,
			&pt.ExternalID,
			&pt.SyncedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan metric series point: %w", err)
		}
		points = append(points, pt)
	}

	return points, nil
}
