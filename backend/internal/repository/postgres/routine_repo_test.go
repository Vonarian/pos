package postgres_test

import (
	"testing"
	"time"

	"github.com/pos/backend/internal/domain"
)

func TestRoutineModelLifecycle(t *testing.T) {
	now := time.Now().UTC()
	item := domain.RoutineItem{
		ID:            "item-test-1",
		Title:         "Morning Supplements",
		Category:      "MEDS",
		TimeWindow:    domain.WindowMorning,
		ScheduledDate: "2026-08-15",
		Status:        domain.StatusPending,
		Metadata:      map[string]any{"nfc_tag": "med_1", "dosage": "1 pill"},
		UpdatedAt:     now,
		CreatedAt:     now,
	}

	if item.Status != domain.StatusPending {
		t.Fatalf("expected PENDING, got %s", item.Status)
	}

	completedAt := now.Add(5 * time.Minute)
	item.Status = domain.StatusCompleted
	item.CompletedAt = &completedAt

	if item.Status != domain.StatusCompleted || item.CompletedAt == nil {
		t.Fatalf("expected COMPLETED with timestamp, got %s", item.Status)
	}
}

func TestHealthMetricPoints(t *testing.T) {
	extID := "hc-step-12345"
	pt := domain.HealthDataPoint{
		ID:         "pt-1",
		Source:     "health_connect",
		Metric:     domain.MetricSteps,
		Value:      5000,
		Unit:       "count",
		StartTime:  time.Now().Add(-30 * time.Minute),
		EndTime:    time.Now(),
		ExternalID: &extID,
		SyncedAt:   time.Now(),
	}

	if err := pt.Validate(); err != nil {
		t.Fatalf("expected valid metric point, got %v", err)
	}

	if *pt.ExternalID != extID {
		t.Errorf("expected external id %s, got %s", extID, *pt.ExternalID)
	}
}
