package domain

import (
	"context"
	"time"
)

type RoutineRepository interface {
	GetByID(ctx context.Context, id string) (*RoutineItem, error)
	ListByDate(ctx context.Context, date string) ([]RoutineItem, error)
	ListSince(ctx context.Context, since time.Time) ([]RoutineItem, error)
	Upsert(ctx context.Context, item *RoutineItem) error
	BatchUpsert(ctx context.Context, items []RoutineItem) error
	UpdateStatus(ctx context.Context, id string, status ItemStatus, completedAt *time.Time) error
	ListActiveTemplates(ctx context.Context) ([]RoutineTemplate, error)
	CreateTemplate(ctx context.Context, template *RoutineTemplate) error
	ResetPendingToMissed(ctx context.Context, beforeDate string) (int64, error)
}

type HealthMetricRepository interface {
	BatchUpsert(ctx context.Context, points []HealthDataPoint) error
	ListSince(ctx context.Context, since time.Time) ([]HealthDataPoint, error)
	GetDailySummary(ctx context.Context, date string) (map[MetricType]float64, error)
	GetMetricSeries(ctx context.Context, metric MetricType, from, to time.Time) ([]HealthDataPoint, error)
}
