package rest_test

import (
	"bytes"
	"encoding/json/v2"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/pos/backend/internal/domain"
)

func TestGetDailySummaryAndIngestEndpoints(t *testing.T) {
	server, _ := setupTestServer(nil)
	handler := server.Routes()

	// 1. Get daily summary
	reqSummary := httptest.NewRequest(http.MethodGet, "/api/v1/metrics/daily-summary?date=2026-08-15", nil)
	recSummary := httptest.NewRecorder()
	handler.ServeHTTP(recSummary, reqSummary)
	if recSummary.Code != http.StatusOK {
		t.Fatalf("expected 200 for summary, got %d", recSummary.Code)
	}

	// 2. Ingest metrics
	points := []domain.HealthDataPoint{
		{
			ID:        "ingest-1",
			Source:    "health_connect",
			Metric:    domain.MetricSteps,
			Value:     7500,
			Unit:      "count",
			StartTime: time.Now().Add(-2 * time.Hour),
			EndTime:   time.Now(),
		},
	}
	bodyIngest, _ := json.Marshal(points)
	reqIngest := httptest.NewRequest(http.MethodPost, "/api/v1/metrics/ingest", bytes.NewReader(bodyIngest))
	recIngest := httptest.NewRecorder()
	handler.ServeHTTP(recIngest, reqIngest)
	if recIngest.Code != http.StatusOK {
		t.Fatalf("expected 200 for ingest, got %d", recIngest.Code)
	}
}
