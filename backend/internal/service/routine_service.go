package service

import (
	"context"
	"errors"
	"fmt"
	"time"
	"uuid"

	"github.com/pos/backend/internal/domain"
)

type QuadrantView struct {
	Date           string               `json:"date"`
	ActiveWindow   domain.TimeWindow    `json:"active_window"`
	Morning        []domain.RoutineItem `json:"morning"`
	Afternoon      []domain.RoutineItem `json:"afternoon"`
	Evening        []domain.RoutineItem `json:"evening"`
	Night          []domain.RoutineItem `json:"night"`
	TotalCount     int                  `json:"total_count"`
	CompletedCount int                  `json:"completed_count"`
	AdherenceRate  float64              `json:"adherence_rate"`
}

type RoutineService struct {
	repo domain.RoutineRepository
}

func NewRoutineService(repo domain.RoutineRepository) *RoutineService {
	return &RoutineService{repo: repo}
}

func GetCurrentTimeWindow(now time.Time) domain.TimeWindow {
	hour := now.Hour()
	switch {
	case hour >= 6 && hour < 12:
		return domain.WindowMorning
	case hour >= 12 && hour < 18:
		return domain.WindowAfternoon
	case hour >= 18 && hour < 21:
		return domain.WindowEvening
	default:
		return domain.WindowNight
	}
}

func GetNextTimeWindow(current domain.TimeWindow) domain.TimeWindow {
	switch current {
	case domain.WindowMorning:
		return domain.WindowAfternoon
	case domain.WindowAfternoon:
		return domain.WindowEvening
	case domain.WindowEvening:
		return domain.WindowNight
	default:
		return domain.WindowNight
	}
}

func (s *RoutineService) GetByID(ctx context.Context, id string) (*domain.RoutineItem, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *RoutineService) CompleteItem(ctx context.Context, id string, completedAt *time.Time) error {
	now := time.Now().UTC()
	if completedAt == nil {
		completedAt = &now
	}
	return s.repo.UpdateStatus(ctx, id, domain.StatusCompleted, completedAt)
}

func (s *RoutineService) SkipItem(ctx context.Context, id string) error {
	return s.repo.UpdateStatus(ctx, id, domain.StatusSkipped, nil)
}

func (s *RoutineService) RevertItem(ctx context.Context, id string) error {
	return s.repo.UpdateStatus(ctx, id, domain.StatusPending, nil)
}

func (s *RoutineService) DeferItem(ctx context.Context, id string) error {
	item, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to fetch item to defer: %w", err)
	}
	if item == nil {
		return errors.New("item not found")
	}

	nextWindow := GetNextTimeWindow(item.TimeWindow)
	item.TimeWindow = nextWindow
	item.UpdatedAt = time.Now().UTC()

	return s.repo.Upsert(ctx, item)
}

func (s *RoutineService) CreateItem(ctx context.Context, item *domain.RoutineItem) error {
	if item.ID == "" {
		item.ID = uuid.New().String()
	}
	if err := item.Validate(); err != nil {
		return fmt.Errorf("invalid routine item: %w", err)
	}
	return s.repo.Upsert(ctx, item)
}

func (s *RoutineService) SyncBatch(ctx context.Context, items []domain.RoutineItem) error {
	return s.repo.BatchUpsert(ctx, items)
}

func (s *RoutineService) ListSince(ctx context.Context, since time.Time) ([]domain.RoutineItem, error) {
	return s.repo.ListSince(ctx, since)
}

func (s *RoutineService) Get4QuadrantView(ctx context.Context, date string, now time.Time) (*QuadrantView, error) {
	items, err := s.repo.ListByDate(ctx, date)
	if err != nil {
		return nil, fmt.Errorf("failed to list routines: %w", err)
	}

	view := &QuadrantView{
		Date:         date,
		ActiveWindow: GetCurrentTimeWindow(now),
		Morning:      make([]domain.RoutineItem, 0),
		Afternoon:    make([]domain.RoutineItem, 0),
		Evening:      make([]domain.RoutineItem, 0),
		Night:        make([]domain.RoutineItem, 0),
		TotalCount:   len(items),
	}

	for _, item := range items {
		if item.Status == domain.StatusCompleted {
			view.CompletedCount++
		}

		switch item.TimeWindow {
		case domain.WindowMorning:
			view.Morning = append(view.Morning, item)
		case domain.WindowAfternoon:
			view.Afternoon = append(view.Afternoon, item)
		case domain.WindowEvening:
			view.Evening = append(view.Evening, item)
		case domain.WindowNight:
			view.Night = append(view.Night, item)
		default:
			view.Morning = append(view.Morning, item)
		}
	}

	if view.TotalCount > 0 {
		view.AdherenceRate = float64(view.CompletedCount) / float64(view.TotalCount)
	}

	return view, nil
}
