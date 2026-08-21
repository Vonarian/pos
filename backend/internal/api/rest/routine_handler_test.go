package rest_test

import (
	"bytes"
	"context"
	"encoding/json/v2"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/pos/backend/internal/api/rest"
	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

func setupTestServer(items map[string]domain.RoutineItem) (*rest.Server, *mockRoutineRepo) {
	rRepo := &mockRoutineRepo{items: items}
	mRepo := &mockMetricRepo{}
	rSvc := service.NewRoutineService(rRepo)
	mSvc := service.NewMetricService(mRepo)
	cSvc := service.NewCronService(rRepo)
	return rest.NewServer(rSvc, mSvc, cSvc, nil), rRepo
}

func TestCompleteAndSkipRoutineEndpoints(t *testing.T) {
	server, rRepo := setupTestServer(map[string]domain.RoutineItem{
		"r-1": {
			ID:            "r-1",
			Title:         "Creatine",
			Category:      "MEDS",
			TimeWindow:    domain.WindowMorning,
			ScheduledDate: "2026-08-15",
			Status:        domain.StatusPending,
		},
		"r-2": {
			ID:            "r-2",
			Title:         "Afternoon Walk",
			Category:      "HABIT",
			TimeWindow:    domain.WindowAfternoon,
			ScheduledDate: "2026-08-15",
			Status:        domain.StatusPending,
		},
	})
	handler := server.Routes()

	// Complete r-1
	bodyComplete, _ := json.Marshal(rest.ActionRequest{ID: "r-1"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/routines/complete", bytes.NewReader(bodyComplete))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected complete status 200, got %d", rec.Code)
	}
	item1, _ := rRepo.GetByID(context.Background(), "r-1")
	if item1.Status != domain.StatusCompleted {
		t.Fatalf("expected r-1 to be COMPLETED, got %s", item1.Status)
	}

	// Skip r-2
	bodySkip, _ := json.Marshal(rest.ActionRequest{ID: "r-2"})
	reqSkip := httptest.NewRequest(http.MethodPost, "/api/v1/routines/skip", bytes.NewReader(bodySkip))
	reqSkip.Header.Set("Content-Type", "application/json")
	recSkip := httptest.NewRecorder()
	handler.ServeHTTP(recSkip, reqSkip)
	if recSkip.Code != http.StatusOK {
		t.Fatalf("expected skip status 200, got %d", recSkip.Code)
	}
	item2, _ := rRepo.GetByID(context.Background(), "r-2")
	if item2.Status != domain.StatusSkipped {
		t.Fatalf("expected r-2 to be SKIPPED, got %s", item2.Status)
	}
}

func TestDeferAndCreateRoutineEndpoints(t *testing.T) {
	server, rRepo := setupTestServer(map[string]domain.RoutineItem{
		"r-defer": {
			ID:            "r-defer",
			Title:         "Morning Task",
			Category:      "TASK",
			TimeWindow:    domain.WindowMorning,
			ScheduledDate: "2026-08-15",
			Status:        domain.StatusPending,
		},
	})
	handler := server.Routes()

	// Defer
	bodyDefer, _ := json.Marshal(rest.ActionRequest{ID: "r-defer"})
	reqDefer := httptest.NewRequest(http.MethodPost, "/api/v1/routines/defer", bytes.NewReader(bodyDefer))
	recDefer := httptest.NewRecorder()
	handler.ServeHTTP(recDefer, reqDefer)
	if recDefer.Code != http.StatusOK {
		t.Fatalf("expected defer status 200, got %d", recDefer.Code)
	}

	deferred, _ := rRepo.GetByID(context.Background(), "r-defer")
	if deferred.TimeWindow != domain.WindowAfternoon {
		t.Fatalf("expected deferred window AFTERNOON, got %s", deferred.TimeWindow)
	}

	// Create
	newItem := domain.RoutineItem{
		Title:         "Night Meditation",
		Category:      "HABIT",
		TimeWindow:    domain.WindowNight,
		ScheduledDate: "2026-08-15",
	}
	bodyCreate, _ := json.Marshal(newItem)
	reqCreate := httptest.NewRequest(http.MethodPost, "/api/v1/routines", bytes.NewReader(bodyCreate))
	recCreate := httptest.NewRecorder()
	handler.ServeHTTP(recCreate, reqCreate)
	if recCreate.Code != http.StatusCreated {
		t.Fatalf("expected create status 201, got %d", recCreate.Code)
	}
}

func TestGetQuadrantsEndpoint(t *testing.T) {
	server, _ := setupTestServer(map[string]domain.RoutineItem{
		"q-1": {
			ID:            "q-1",
			Title:         "Cold Shower",
			Category:      "HABIT",
			TimeWindow:    domain.WindowMorning,
			ScheduledDate: "2026-08-15",
			Status:        domain.StatusCompleted,
		},
	})
	handler := server.Routes()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/routines/quadrants?date=2026-08-15", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}

	var view service.QuadrantView
	if err := json.UnmarshalRead(rec.Body, &view); err != nil {
		t.Fatalf("failed to decode quadrant view: %v", err)
	}
	if view.TotalCount != 1 || view.CompletedCount != 1 {
		t.Fatalf("expected 1 total and 1 completed, got %d and %d", view.TotalCount, view.CompletedCount)
	}
}
