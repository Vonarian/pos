package domain

import (
	"errors"
	"time"
)

type RoutineItem struct {
	ID            string         `json:"id" db:"id"`
	TemplateID    *string        `json:"template_id,omitempty" db:"template_id"`
	Title         string         `json:"title" db:"title"`
	Category      string         `json:"category" db:"category"`
	TimeWindow    TimeWindow     `json:"time_window" db:"time_window"`
	ScheduledDate string         `json:"scheduled_date" db:"scheduled_date"` // YYYY-MM-DD
	Status        ItemStatus     `json:"status" db:"status"`
	CompletedAt   *time.Time     `json:"completed_at,omitempty" db:"completed_at"`
	Metadata      map[string]any `json:"metadata" db:"metadata"`
	UpdatedAt     time.Time      `json:"updated_at" db:"updated_at"`
	CreatedAt     time.Time      `json:"created_at" db:"created_at"`
}

func (r RoutineItem) Validate() error {
	if r.ID == "" {
		return errors.New("id is required")
	}
	if r.Title == "" {
		return errors.New("title is required")
	}
	if r.TimeWindow == "" {
		return errors.New("time_window is required")
	}
	if r.ScheduledDate == "" {
		return errors.New("scheduled_date is required")
	}
	if r.Status == "" {
		return errors.New("status is required")
	}
	return nil
}

type RoutineTemplate struct {
	ID         string         `json:"id" db:"id"`
	Title      string         `json:"title" db:"title"`
	Category   string         `json:"category" db:"category"`
	TimeWindow TimeWindow     `json:"time_window" db:"time_window"`
	DaysOfWeek []int          `json:"days_of_week" db:"days_of_week"` // 0 = Sunday, 1 = Monday...
	Metadata   map[string]any `json:"metadata" db:"metadata"`
	IsActive   bool           `json:"is_active" db:"is_active"`
	CreatedAt  time.Time      `json:"created_at" db:"created_at"`
}

type HealthDataPoint struct {
	ID         string     `json:"id" db:"id"`
	Source     string     `json:"source" db:"source"`
	Metric     MetricType `json:"metric" db:"metric"`
	Value      float64    `json:"value" db:"value"`
	Unit       string     `json:"unit" db:"unit"`
	StartTime  time.Time  `json:"start_time" db:"start_time"`
	EndTime    time.Time  `json:"end_time" db:"end_time"`
	ExternalID *string    `json:"external_id,omitempty" db:"external_id"`
	SyncedAt   time.Time  `json:"synced_at" db:"synced_at"`
}

func (h HealthDataPoint) Validate() error {
	if h.ID == "" {
		return errors.New("id is required")
	}
	if h.Metric == "" {
		return errors.New("metric is required")
	}
	if h.EndTime.Before(h.StartTime) {
		return errors.New("end_time cannot be before start_time")
	}
	return nil
}
