package domain_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/pos/backend/internal/domain"
)

func TestRoutineItemSerialization(t *testing.T) {
	now := time.Now().UTC().Truncate(time.Second)
	item := domain.RoutineItem{
		ID:            "item-123",
		Title:         "Morning Creatine & D3",
		Category:      "MEDS",
		TimeWindow:    domain.WindowMorning,
		ScheduledDate: "2026-08-15",
		Status:        domain.StatusPending,
		Metadata:      map[string]any{"dosage": "5g", "nfc_tag": "med_box_1"},
		UpdatedAt:     now,
		CreatedAt:     now,
	}

	if err := item.Validate(); err != nil {
		t.Fatalf("expected valid item, got error: %v", err)
	}

	data, err := json.Marshal(item)
	if err != nil {
		t.Fatalf("failed to marshal RoutineItem: %v", err)
	}

	var unmarshaled domain.RoutineItem
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("failed to unmarshal RoutineItem: %v", err)
	}

	if unmarshaled.ID != item.ID || unmarshaled.Status != domain.StatusPending {
		t.Errorf("expected ID %s and status %s, got ID %s and status %s", item.ID, item.Status, unmarshaled.ID, unmarshaled.Status)
	}
}

func TestHealthDataPointValidation(t *testing.T) {
	pt := domain.HealthDataPoint{
		ID:        "dp-1",
		Source:    "health_connect",
		Metric:    domain.MetricSteps,
		Value:     8450,
		Unit:      "count",
		StartTime: time.Now().Add(-1 * time.Hour),
		EndTime:   time.Now(),
		SyncedAt:  time.Now(),
	}

	if err := pt.Validate(); err != nil {
		t.Errorf("expected valid data point, got error: %v", err)
	}

	nutPt := domain.HealthDataPoint{
		ID:        "dp-nut-1",
		Source:    "health_connect",
		Metric:    domain.MetricCaloriesConsumed,
		Value:     2450,
		Unit:      "kcal",
		StartTime: time.Now().Add(-1 * time.Hour),
		EndTime:   time.Now(),
		SyncedAt:  time.Now(),
	}
	if err := nutPt.Validate(); err != nil {
		t.Errorf("expected valid nutrition data point, got error: %v", err)
	}

	invalidPt := domain.HealthDataPoint{
		ID:        "dp-2",
		Source:    "health_connect",
		Metric:    "",
		StartTime: time.Now(),
		EndTime:   time.Now().Add(-1 * time.Hour),
	}

	if err := invalidPt.Validate(); err == nil {
		t.Errorf("expected error for invalid data point, got nil")
	}
}
