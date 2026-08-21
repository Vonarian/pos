package service

import (
	"context"
	"fmt"
	"log/slog"
	"time"
	"uuid"

	"github.com/pos/backend/internal/domain"
)

type CronService struct {
	repo domain.RoutineRepository
}

func NewCronService(repo domain.RoutineRepository) *CronService {
	return &CronService{repo: repo}
}

func (c *CronService) ExecuteDailyRollover(ctx context.Context, todayDate string) error {
	today, err := time.Parse("2006-01-02", todayDate)
	if err != nil {
		return fmt.Errorf("invalid today date format %s: %w", todayDate, err)
	}

	// 1. Reset pending items before today to MISSED
	missedCount, err := c.repo.ResetPendingToMissed(ctx, todayDate)
	if err != nil {
		return fmt.Errorf("failed to reset pending items to missed: %w", err)
	}
	slog.Info("Midnight reset completed", "missed_items_transitioned", missedCount, "date", todayDate)

	// 2. Fetch active routine templates
	templates, err := c.repo.ListActiveTemplates(ctx)
	if err != nil {
		return fmt.Errorf("failed to list active templates: %w", err)
	}

	// 3. Fetch existing items for today to avoid duplicate creation
	existingItems, err := c.repo.ListByDate(ctx, todayDate)
	if err != nil {
		return fmt.Errorf("failed to list existing items for today: %w", err)
	}

	existingTemplateIDs := make(map[string]bool)
	for _, item := range existingItems {
		if item.TemplateID != nil {
			existingTemplateIDs[*item.TemplateID] = true
		}
	}

	// 4. Generate today's routine items based on weekday
	weekday := int(today.Weekday()) // 0 = Sunday, 1 = Monday, etc.
	var newItems []domain.RoutineItem
	now := time.Now().UTC()

	for _, tpl := range templates {
		if existingTemplateIDs[tpl.ID] {
			continue
		}

		dayMatches := false
		if len(tpl.DaysOfWeek) == 0 {
			dayMatches = true // everyday by default
		} else {
			for _, d := range tpl.DaysOfWeek {
				if d == weekday {
					dayMatches = true
					break
				}
			}
		}

		if dayMatches {
			tplID := tpl.ID
			newItems = append(newItems, domain.RoutineItem{
				ID:            uuid.New().String(),
				TemplateID:    &tplID,
				Title:         tpl.Title,
				Category:      tpl.Category,
				TimeWindow:    tpl.TimeWindow,
				ScheduledDate: todayDate,
				Status:        domain.StatusPending,
				Metadata:      tpl.Metadata,
				UpdatedAt:     now,
				CreatedAt:     now,
			})
		}
	}

	if len(newItems) > 0 {
		if err := c.repo.BatchUpsert(ctx, newItems); err != nil {
			return fmt.Errorf("failed to spawn today's routine items: %w", err)
		}
		slog.Info("Spawned daily routine items from templates", "count", len(newItems), "date", todayDate)
	}

	return nil
}

func (c *CronService) StartMidnightTicker(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	lastRolloverDate := ""

	for {
		select {
		case <-ctx.Done():
			return
		case now := <-ticker.C:
			currentDate := now.Format("2006-01-02")
			// If it's a new day and we haven't rolled over yet
			if currentDate != lastRolloverDate {
				if err := c.ExecuteDailyRollover(ctx, currentDate); err != nil {
					slog.Error("Failed to execute daily rollover cron", "error", err, "date", currentDate)
				} else {
					lastRolloverDate = currentDate
				}
			}
		}
	}
}
