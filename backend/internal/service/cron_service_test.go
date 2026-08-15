package service_test

import (
	"context"
	"testing"

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

	repo.templates = []domain.RoutineTemplate{
		{
			ID:         "tpl-d3",
			Title:      "Vitamin D3",
			Category:   "MEDS",
			TimeWindow: domain.WindowMorning,
			DaysOfWeek: []int{0, 1, 2, 3, 4, 5, 6}, // everyday
			IsActive:   true,
		},
	}

	cronSvc := service.NewCronService(repo)
	err := cronSvc.ExecuteDailyRollover(context.Background(), "2026-08-15")
	if err != nil {
		t.Fatalf("failed to execute daily rollover: %v", err)
	}

	// 1. Check yesterday's pending item transitioned to MISSED
	yesterdayItem := repo.items["yesterday-1"]
	if yesterdayItem.Status != domain.StatusMissed {
		t.Errorf("expected yesterday item to be MISSED, got %s", yesterdayItem.Status)
	}

	// 2. Check today's routine item was spawned
	todayItems, _ := repo.ListByDate(context.Background(), "2026-08-15")
	if len(todayItems) != 1 {
		t.Fatalf("expected 1 spawned item for today, got %d", len(todayItems))
	}
	if todayItems[0].Title != "Vitamin D3" || todayItems[0].Status != domain.StatusPending {
		t.Errorf("expected spawned Vitamin D3 with PENDING, got %s / %s", todayItems[0].Title, todayItems[0].Status)
	}
}
