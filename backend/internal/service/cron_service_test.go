package service_test

import (
	"context"
	"testing"
	"uuid"

	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

func TestMidnightResetAndSpawn(t *testing.T) {
	repo := newMockRoutineRepo()
	repo.items["yesterday-1"] = domain.RoutineItem{
		ID:            "yesterday-1",
		Title:         "Old Pending",
		TimeWindow:    domain.WindowNight,
		ScheduledDate: "2026-08-14",
		Status:        domain.StatusPending,
	}
	repo.templates = []domain.RoutineTemplate{{
		ID:         "tpl-d3",
		Title:      "Vitamin D3",
		Category:   "MEDS",
		TimeWindow: domain.WindowMorning,
		DaysOfWeek: []int{0, 1, 2, 3, 4, 5, 6},
		IsActive:   true,
	}}

	cronSvc := service.NewCronService(repo)
	if err := cronSvc.ExecuteDailyRollover(context.Background(), "2026-08-15"); err != nil {
		t.Fatalf("failed to execute daily rollover: %v", err)
	}

	t.Run("transitions yesterday pending to missed", func(t *testing.T) {
		yesterdayItem := repo.items["yesterday-1"]
		if yesterdayItem.Status != domain.StatusMissed {
			t.Errorf("expected yesterday item to be MISSED, got %s", yesterdayItem.Status)
		}
	})

	t.Run("spawns today item from template with valid uuid", func(t *testing.T) {
		todayItems, _ := repo.ListByDate(context.Background(), "2026-08-15")
		if len(todayItems) != 1 {
			t.Fatalf("expected 1 spawned item for today, got %d", len(todayItems))
		}
		if todayItems[0].Title != "Vitamin D3" || todayItems[0].Status != domain.StatusPending {
			t.Errorf("expected Vitamin D3 PENDING, got %s / %s", todayItems[0].Title, todayItems[0].Status)
		}
		parsed, err := uuid.Parse(todayItems[0].ID)
		if err != nil || parsed == uuid.Nil() {
			t.Fatalf("expected valid non-nil UUID for spawned item, got: %v (%s)", err, todayItems[0].ID)
		}
	})
}
