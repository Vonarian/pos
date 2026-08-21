package service

import (
	"context"
	"fmt"
	"time"
	"uuid"

	"github.com/pos/backend/internal/domain"
)

type MetricSummary struct {
	Date           string  `json:"date"`
	Steps          float64 `json:"steps"`
	CaloriesBurned float64 `json:"calories_burned"`
	SleepMinutes   float64 `json:"sleep_minutes"`
	WeightKg       float64 `json:"weight_kg"`
	BodyFatPct     float64 `json:"body_fat_pct"`
}

type MetricService struct {
	repo domain.HealthMetricRepository
}

func NewMetricService(repo domain.HealthMetricRepository) *MetricService {
	return &MetricService{repo: repo}
}

func (s *MetricService) IngestMetrics(ctx context.Context, points []domain.HealthDataPoint) error {
	validated := make([]domain.HealthDataPoint, 0, len(points))
	now := time.Now().UTC()

	for _, pt := range points {
		if pt.ID == "" {
			pt.ID = uuid.New().String()
		}
		if pt.SyncedAt.IsZero() {
			pt.SyncedAt = now
		}
		if err := pt.Validate(); err != nil {
			return fmt.Errorf("invalid metric point: %w", err)
		}
		validated = append(validated, pt)
	}

	return s.repo.BatchUpsert(ctx, validated)
}

func (s *MetricService) ListSince(ctx context.Context, since time.Time) ([]domain.HealthDataPoint, error) {
	return s.repo.ListSince(ctx, since)
}

func (s *MetricService) GetDailySummary(ctx context.Context, date string) (*MetricSummary, error) {
	rawSummary, err := s.repo.GetDailySummary(ctx, date)
	if err != nil {
		return nil, fmt.Errorf("failed to get daily metrics: %w", err)
	}

	summary := &MetricSummary{
		Date:           date,
		Steps:          rawSummary[domain.MetricSteps],
		CaloriesBurned: rawSummary[domain.MetricCaloriesBurned],
		SleepMinutes:   rawSummary[domain.MetricSleepDuration],
		WeightKg:       rawSummary[domain.MetricWeight],
		BodyFatPct:     rawSummary[domain.MetricBodyFat],
	}

	return summary, nil
}

func (s *MetricService) GetMetricSeries(ctx context.Context, metric domain.MetricType, from, to time.Time) ([]domain.HealthDataPoint, error) {
	return s.repo.GetMetricSeries(ctx, metric, from, to)
}
