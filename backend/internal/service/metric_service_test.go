package service_test

import (
	"context"
	"testing"
	"time"

	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

type mockMetricRepo struct {
	points  []domain.HealthDataPoint
	summary map[domain.MetricType]float64
}

func (m *mockMetricRepo) BatchUpsert(ctx context.Context, points []domain.HealthDataPoint) error {
	m.points = append(m.points, points...)
	return nil
}

func (m *mockMetricRepo) ListSince(ctx context.Context, since time.Time) ([]domain.HealthDataPoint, error) {
	return m.points, nil
}

func (m *mockMetricRepo) GetDailySummary(ctx context.Context, date string) (map[domain.MetricType]float64, error) {
	return m.summary, nil
}

func (m *mockMetricRepo) GetMetricSeries(ctx context.Context, metric domain.MetricType, from, to time.Time) ([]domain.HealthDataPoint, error) {
	var res []domain.HealthDataPoint
	for _, pt := range m.points {
		if pt.Metric == metric {
			res = append(res, pt)
		}
	}
	return res, nil
}

func TestMetricServiceSummary(t *testing.T) {
	repo := &mockMetricRepo{
		summary: map[domain.MetricType]float64{
			domain.MetricSteps:          10250,
			domain.MetricCaloriesBurned: 2450,
			domain.MetricSleepDuration:  480,
			domain.MetricWeight:         81.5,
		},
	}
	svc := service.NewMetricService(repo)

	summary, err := svc.GetDailySummary(context.Background(), "2026-08-15")
	if err != nil {
		t.Fatalf("failed to get daily summary: %v", err)
	}

	if summary.Steps != 10250 || summary.CaloriesBurned != 2450 || summary.SleepMinutes != 480 || summary.WeightKg != 81.5 {
		t.Errorf("summary values mismatch: %+v", summary)
	}
}
