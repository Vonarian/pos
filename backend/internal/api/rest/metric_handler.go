package rest

import (
	"encoding/json/v2"
	"net/http"
	"time"

	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/domain"
)

func (s *Server) handleGetDailySummary(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	summary, err := s.metricSvc.GetDailySummary(r.Context(), dateStr)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, summary)
}

func (s *Server) handleGetMetricSeries(w http.ResponseWriter, r *http.Request) {
	metricStr := r.URL.Query().Get("metric")
	fromStr := r.URL.Query().Get("from")
	toStr := r.URL.Query().Get("to")

	if metricStr == "" {
		respondError(w, http.StatusBadRequest, "metric is required")
		return
	}

	from := time.Now().AddDate(0, 0, -30)
	to := time.Now()

	if fromStr != "" {
		if t, err := time.Parse("2006-01-02", fromStr); err == nil {
			from = t
		}
	}
	if toStr != "" {
		if t, err := time.Parse("2006-01-02", toStr); err == nil {
			to = t
		}
	}

	series, err := s.metricSvc.GetMetricSeries(r.Context(), domain.MetricType(metricStr), from, to)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, series)
}

func (s *Server) handleIngestMetrics(w http.ResponseWriter, r *http.Request) {
	var points []domain.HealthDataPoint
	if err := json.UnmarshalRead(r.Body, &points); err != nil {
		respondError(w, http.StatusBadRequest, "invalid json array of metrics")
		return
	}

	if err := s.metricSvc.IngestMetrics(r.Context(), points); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventMetricsIngested, map[string]int{"count": len(points)})
	}

	respondJSON(w, http.StatusOK, map[string]any{
		"ingested_count": len(points),
		"status":         "ok",
	})
}
