package service_test

import (
	"context"
	"testing"
	"time"
	"uuid"

	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

type mockRoutineRepo struct {
	items     map[string]domain.RoutineItem
	templates []domain.RoutineTemplate
}

func newMockRoutineRepo() *mockRoutineRepo {
	return &mockRoutineRepo{
		items:     make(map[string]domain.RoutineItem),
		templates: make([]domain.RoutineTemplate, 0),
	}
}

func (m *mockRoutineRepo) GetByID(ctx context.Context, id string) (*domain.RoutineItem, error) {
	item, ok := m.items[id]
	if !ok {
		return nil, nil
	}
	return &item, nil
}

func (m *mockRoutineRepo) ListByDate(ctx context.Context, date string) ([]domain.RoutineItem, error) {
	var list []domain.RoutineItem
	for _, item := range m.items {
		if item.ScheduledDate == date {
			list = append(list, item)
		}
	}
	return list, nil
}

func (m *mockRoutineRepo) ListSince(ctx context.Context, since time.Time) ([]domain.RoutineItem, error) {
	var list []domain.RoutineItem
	for _, item := range m.items {
		if item.UpdatedAt.After(since) {
			list = append(list, item)
		}
	}
	return list, nil
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
	return m.templates, nil
}

func (m *mockRoutineRepo) CreateTemplate(ctx context.Context, template *domain.RoutineTemplate) error {
	m.templates = append(m.templates, *template)
	return nil
}

func (m *mockRoutineRepo) ResetPendingToMissed(ctx context.Context, beforeDate string) (int64, error) {
	var count int64
	for k, item := range m.items {
		if item.ScheduledDate < beforeDate && item.Status == domain.StatusPending {
			item.Status = domain.StatusMissed
			item.UpdatedAt = time.Now().UTC()
			m.items[k] = item
			count++
		}
	}
	return count, nil
}

func TestTimeWindowCalculations(t *testing.T) {
	morning := time.Date(2026, 8, 15, 8, 30, 0, 0, time.UTC)
	if w := service.GetCurrentTimeWindow(morning); w != domain.WindowMorning {
		t.Errorf("expected MORNING, got %s", w)
	}

	afternoon := time.Date(2026, 8, 15, 14, 0, 0, 0, time.UTC)
	if w := service.GetCurrentTimeWindow(afternoon); w != domain.WindowAfternoon {
		t.Errorf("expected AFTERNOON, got %s", w)
	}

	evening := time.Date(2026, 8, 15, 19, 0, 0, 0, time.UTC)
	if w := service.GetCurrentTimeWindow(evening); w != domain.WindowEvening {
		t.Errorf("expected EVENING, got %s", w)
	}

	night := time.Date(2026, 8, 15, 23, 0, 0, 0, time.UTC)
	if w := service.GetCurrentTimeWindow(night); w != domain.WindowNight {
		t.Errorf("expected NIGHT, got %s", w)
	}
}

func TestRoutineServiceStateTransitions(t *testing.T) {
	repo := newMockRoutineRepo()
	svc := service.NewRoutineService(repo)

	item := domain.RoutineItem{
		ID:            "item-1",
		Title:         "Creatine",
		Category:      "MEDS",
		TimeWindow:    domain.WindowMorning,
		ScheduledDate: "2026-08-15",
		Status:        domain.StatusPending,
	}
	if err := svc.CreateItem(context.Background(), &item); err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Test Defer (Morning -> Afternoon)
	if err := svc.DeferItem(context.Background(), "item-1"); err != nil {
		t.Fatalf("failed to defer item: %v", err)
	}
	deferred, _ := svc.GetByID(context.Background(), "item-1")
	if deferred.TimeWindow != domain.WindowAfternoon {
		t.Errorf("expected deferred window AFTERNOON, got %s", deferred.TimeWindow)
	}

	// Test Complete
	now := time.Now().UTC()
	if err := svc.CompleteItem(context.Background(), "item-1", &now); err != nil {
		t.Fatalf("failed to complete item: %v", err)
	}
	completed, _ := svc.GetByID(context.Background(), "item-1")
	if completed.Status != domain.StatusCompleted || completed.CompletedAt.IsZero() {
		t.Errorf("expected COMPLETED with timestamp, got %s", completed.Status)
	}
}

func Test4QuadrantView(t *testing.T) {
	repo := newMockRoutineRepo()
	svc := service.NewRoutineService(repo)

	repo.items["m1"] = domain.RoutineItem{ID: "m1", Title: "D3", TimeWindow: domain.WindowMorning, ScheduledDate: "2026-08-15", Status: domain.StatusCompleted}
	repo.items["a1"] = domain.RoutineItem{ID: "a1", Title: "Lunch", TimeWindow: domain.WindowAfternoon, ScheduledDate: "2026-08-15", Status: domain.StatusPending}
	repo.items["e1"] = domain.RoutineItem{ID: "e1", Title: "Gym", TimeWindow: domain.WindowEvening, ScheduledDate: "2026-08-15", Status: domain.StatusPending}
	repo.items["n1"] = domain.RoutineItem{ID: "n1", Title: "Magnesium", TimeWindow: domain.WindowNight, ScheduledDate: "2026-08-15", Status: domain.StatusPending}

	testTime := time.Date(2026, 8, 15, 9, 0, 0, 0, time.UTC)
	view, err := svc.Get4QuadrantView(context.Background(), "2026-08-15", testTime)
	if err != nil {
		t.Fatalf("failed to get 4-quadrant view: %v", err)
	}

	if view.ActiveWindow != domain.WindowMorning {
		t.Errorf("expected active window MORNING, got %s", view.ActiveWindow)
	}
	if len(view.Morning) != 1 || len(view.Afternoon) != 1 || len(view.Evening) != 1 || len(view.Night) != 1 {
		t.Errorf("expected 1 item per quadrant, got %d, %d, %d, %d", len(view.Morning), len(view.Afternoon), len(view.Evening), len(view.Night))
	}
	if view.CompletedCount != 1 || view.TotalCount != 4 {
		t.Errorf("expected 1/4 completed, got %d/%d", view.CompletedCount, view.TotalCount)
	}
	if view.AdherenceRate != 0.25 {
		t.Errorf("expected adherence rate 0.25, got %f", view.AdherenceRate)
	}
}

func TestRoutineServiceCreateGeneratesUUID(t *testing.T) {
	repo := newMockRoutineRepo()
	svc := service.NewRoutineService(repo)

	item := domain.RoutineItem{
		Title:         "Hydrate",
		Category:      "HEALTH",
		TimeWindow:    domain.WindowMorning,
		ScheduledDate: "2026-08-15",
		Status:        domain.StatusPending,
	}

	if err := svc.CreateItem(context.Background(), &item); err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	if item.ID == "" {
		t.Fatal("expected item.ID to be populated")
	}

	parsed, err := uuid.Parse(item.ID)
	if err != nil {
		t.Fatalf("expected valid UUID, got error: %v (id: %s)", err, item.ID)
	}
	if parsed == uuid.Nil() {
		t.Error("expected non-nil UUID")
	}
}
