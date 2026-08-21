package rest_test

import (
	"bytes"
	"context"
	"encoding/json/v2"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/pos/backend/internal/api/rest"
	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

type mockRoutineRepo struct {
	items map[string]domain.RoutineItem
}

func (m *mockRoutineRepo) GetByID(ctx context.Context, id string) (*domain.RoutineItem, error) {
	item, ok := m.items[id]
	if !ok {
		return nil, nil
	}
	return &item, nil
}
func (m *mockRoutineRepo) ListByDate(ctx context.Context, date string) ([]domain.RoutineItem, error) {
	var res []domain.RoutineItem
	for _, item := range m.items {
		if item.ScheduledDate == date {
			res = append(res, item)
		}
	}
	return res, nil
}
func (m *mockRoutineRepo) ListSince(ctx context.Context, since time.Time) ([]domain.RoutineItem, error) {
	var res []domain.RoutineItem
	for _, item := range m.items {
		if item.UpdatedAt.After(since) {
			res = append(res, item)
		}
	}
	return res, nil
}
func (m *mockRoutineRepo) Upsert(ctx context.Context, item *domain.RoutineItem) error {
	m.items[item.ID] = *item
	return nil
}
func (m *mockRoutineRepo) BatchUpsert(ctx context.Context, items []domain.RoutineItem) error {
	for _, item := range items {
		m.items[item.ID] = item
	}
	return nil
}
func (m *mockRoutineRepo) UpdateStatus(ctx context.Context, id string, status domain.ItemStatus, completedAt *time.Time) error {
	item, ok := m.items[id]
	if !ok {
		return nil
	}
	item.Status = status
	if completedAt != nil {
		item.CompletedAt = *completedAt
	} else {
		item.CompletedAt = time.Time{}
	}
	item.UpdatedAt = time.Now().UTC()
	m.items[id] = item
	return nil
}
func (m *mockRoutineRepo) ListActiveTemplates(ctx context.Context) ([]domain.RoutineTemplate, error) {
	return nil, nil
}
func (m *mockRoutineRepo) CreateTemplate(ctx context.Context, template *domain.RoutineTemplate) error {
	return nil
}
func (m *mockRoutineRepo) ResetPendingToMissed(ctx context.Context, beforeDate string) (int64, error) {
	return 0, nil
}

type mockMetricRepo struct {
	points []domain.HealthDataPoint
}

func (m *mockMetricRepo) BatchUpsert(ctx context.Context, points []domain.HealthDataPoint) error {
	m.points = append(m.points, points...)
	return nil
}
func (m *mockMetricRepo) ListSince(ctx context.Context, since time.Time) ([]domain.HealthDataPoint, error) {
	return m.points, nil
}
func (m *mockMetricRepo) GetDailySummary(ctx context.Context, date string) (map[domain.MetricType]float64, error) {
	return map[domain.MetricType]float64{
		domain.MetricSteps: 8500,
	}, nil
}
func (m *mockMetricRepo) GetMetricSeries(ctx context.Context, metric domain.MetricType, from, to time.Time) ([]domain.HealthDataPoint, error) {
	return m.points, nil
}

func TestHealthCheckEndpoint(t *testing.T) {
	rRepo := &mockRoutineRepo{items: make(map[string]domain.RoutineItem)}
	mRepo := &mockMetricRepo{}
	rSvc := service.NewRoutineService(rRepo)
	mSvc := service.NewMetricService(mRepo)
	cSvc := service.NewCronService(rRepo)

	server := rest.NewServer(rSvc, mSvc, cSvc, nil)
	handler := server.Routes()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/health", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
}

func TestSyncPushAndPull(t *testing.T) {
	rRepo := &mockRoutineRepo{items: make(map[string]domain.RoutineItem)}
	mRepo := &mockMetricRepo{}
	rSvc := service.NewRoutineService(rRepo)
	mSvc := service.NewMetricService(mRepo)
	cSvc := service.NewCronService(rRepo)

	server := rest.NewServer(rSvc, mSvc, cSvc, nil)
	handler := server.Routes()

	// 1. Push
	pushReq := rest.SyncPushRequest{
		Routines: []domain.RoutineItem{
			{
				ID:            "sync-item-1",
				Title:         "Afternoon Walk",
				Category:      "HABIT",
				TimeWindow:    domain.WindowAfternoon,
				ScheduledDate: "2026-08-15",
				Status:        domain.StatusPending,
				UpdatedAt:     time.Now().UTC(),
			},
		},
		Metrics: []domain.HealthDataPoint{
			{
				ID:        "sync-metric-1",
				Source:    "health_connect",
				Metric:    domain.MetricSteps,
				Value:     5200,
				Unit:      "count",
				StartTime: time.Now().Add(-1 * time.Hour),
				EndTime:   time.Now(),
				SyncedAt:  time.Now().UTC(),
			},
		},
	}

	body, _ := json.Marshal(pushReq)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected sync push 200, got %d. Body: %s", rec.Code, rec.Body.String())
	}

	// 2. Pull
	reqPull := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pull", nil)
	recPull := httptest.NewRecorder()

	handler.ServeHTTP(recPull, reqPull)
	if recPull.Code != http.StatusOK {
		t.Fatalf("expected sync pull 200, got %d", recPull.Code)
	}

	var pullResp rest.SyncPullResponse
	if err := json.UnmarshalRead(recPull.Body, &pullResp); err != nil {
		t.Fatalf("failed to decode pull response: %v", err)
	}

	if len(pullResp.Routines) != 1 || len(pullResp.Metrics) != 1 {
		t.Fatalf("expected 1 routine and 1 metric, got %d and %d", len(pullResp.Routines), len(pullResp.Metrics))
	}
}

func TestRevertRoutineEndpoint(t *testing.T) {
	rRepo := &mockRoutineRepo{items: map[string]domain.RoutineItem{
		"routine-1": {
			ID:            "routine-1",
			Title:         "Morning Stretch",
			Category:      "HABIT",
			TimeWindow:    domain.WindowMorning,
			ScheduledDate: "2026-08-15",
			Status:        domain.StatusCompleted,
		},
	}}
	mRepo := &mockMetricRepo{}
	rSvc := service.NewRoutineService(rRepo)
	mSvc := service.NewMetricService(mRepo)
	cSvc := service.NewCronService(rRepo)

	server := rest.NewServer(rSvc, mSvc, cSvc, nil)
	handler := server.Routes()

	body, _ := json.Marshal(rest.ActionRequest{ID: "routine-1"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/routines/revert", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	item, _ := rRepo.GetByID(context.Background(), "routine-1")
	if item.Status != domain.StatusPending {
		t.Fatalf("expected routine to be PENDING after revert, got %s", item.Status)
	}
}

func TestGetMetricSeriesEndpoint(t *testing.T) {
	rRepo := &mockRoutineRepo{items: make(map[string]domain.RoutineItem)}
	mRepo := &mockMetricRepo{points: []domain.HealthDataPoint{
		{
			ID:        "p1",
			Source:    "health_connect",
			Metric:    domain.MetricSteps,
			Value:     10000,
			Unit:      "count",
			StartTime: time.Now().AddDate(0, 0, -1),
			EndTime:   time.Now(),
		},
	}}
	rSvc := service.NewRoutineService(rRepo)
	mSvc := service.NewMetricService(mRepo)
	cSvc := service.NewCronService(rRepo)

	server := rest.NewServer(rSvc, mSvc, cSvc, nil)
	handler := server.Routes()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/metrics/series?metric=STEPS&from=2026-08-01&to=2026-08-15", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	var series []domain.HealthDataPoint
	if err := json.UnmarshalRead(rec.Body, &series); err != nil {
		t.Fatalf("failed to decode metric series: %v", err)
	}
	if len(series) != 1 {
		t.Fatalf("expected 1 metric series item, got %d", len(series))
	}
}
