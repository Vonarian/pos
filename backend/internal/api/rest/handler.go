package rest

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

type Server struct {
	routineSvc *service.RoutineService
	metricSvc  *service.MetricService
	cronSvc    *service.CronService
	wsHub      *ws.Hub
	version    string
	commit     string
	buildDate  string
}

func NewServer(
	routineSvc *service.RoutineService,
	metricSvc *service.MetricService,
	cronSvc *service.CronService,
	wsHub *ws.Hub,
) *Server {
	return &Server{
		routineSvc: routineSvc,
		metricSvc:  metricSvc,
		cronSvc:    cronSvc,
		wsHub:      wsHub,
		version:    "0.1.0-dev",
	}
}

func (s *Server) SetVersion(version string) {
	if version != "" {
		s.version = version
	}
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()

	// Health Check
	mux.HandleFunc("GET /api/v1/health", s.handleHealthCheck)

	// Routines & Quadrants
	mux.HandleFunc("GET /api/v1/routines/quadrants", s.handleGetQuadrants)
	mux.HandleFunc("POST /api/v1/routines/complete", s.handleCompleteRoutine)
	mux.HandleFunc("POST /api/v1/routines/skip", s.handleSkipRoutine)
	mux.HandleFunc("POST /api/v1/routines/defer", s.handleDeferRoutine)
	mux.HandleFunc("POST /api/v1/routines/revert", s.handleRevertRoutine)
	mux.HandleFunc("POST /api/v1/routines", s.handleCreateRoutine)

	// Metrics
	mux.HandleFunc("GET /api/v1/metrics/daily-summary", s.handleGetDailySummary)
	mux.HandleFunc("GET /api/v1/metrics/series", s.handleGetMetricSeries)
	mux.HandleFunc("POST /api/v1/metrics/ingest", s.handleIngestMetrics)

	// Delta Sync
	mux.HandleFunc("POST /api/v1/sync/push", s.handleSyncPush)
	mux.HandleFunc("GET /api/v1/sync/pull", s.handleSyncPull)

	// WebSocket Hub
	if s.wsHub != nil {
		mux.HandleFunc("GET /api/v1/ws", s.wsHub.ServeWS)
	}

	return mux
}

func (s *Server) handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]any{
		"status":     "healthy",
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
		"version":    s.version,
		"commit":     s.commit,
		"build_date": s.buildDate,
	})
}

func (s *Server) handleGetQuadrants(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	view, err := s.routineSvc.Get4QuadrantView(r.Context(), dateStr, time.Now())
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, view)
}

type ActionRequest struct {
	ID          string     `json:"id"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

func (s *Server) handleCompleteRoutine(w http.ResponseWriter, r *http.Request) {
	var req ActionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ID == "" {
		respondError(w, http.StatusBadRequest, "invalid request body, id is required")
		return
	}

	if err := s.routineSvc.CompleteItem(r.Context(), req.ID, req.CompletedAt); err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventRoutineCompleted, map[string]string{"id": req.ID})
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "COMPLETED", "id": req.ID})
}

func (s *Server) handleSkipRoutine(w http.ResponseWriter, r *http.Request) {
	var req ActionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ID == "" {
		respondError(w, http.StatusBadRequest, "invalid request body, id is required")
		return
	}

	if err := s.routineSvc.SkipItem(r.Context(), req.ID); err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventRoutineUpdated, map[string]string{"id": req.ID, "status": "SKIPPED"})
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "SKIPPED", "id": req.ID})
}

func (s *Server) handleDeferRoutine(w http.ResponseWriter, r *http.Request) {
	var req ActionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ID == "" {
		respondError(w, http.StatusBadRequest, "invalid request body, id is required")
		return
	}

	if err := s.routineSvc.DeferItem(r.Context(), req.ID); err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventRoutineUpdated, map[string]string{"id": req.ID, "status": "DEFERRED"})
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "DEFERRED", "id": req.ID})
}

func (s *Server) handleRevertRoutine(w http.ResponseWriter, r *http.Request) {
	var req ActionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ID == "" {
		respondError(w, http.StatusBadRequest, "invalid request body, id is required")
		return
	}

	if err := s.routineSvc.RevertItem(r.Context(), req.ID); err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventRoutineUpdated, map[string]string{"id": req.ID, "status": "PENDING"})
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "PENDING", "id": req.ID})
}

func (s *Server) handleCreateRoutine(w http.ResponseWriter, r *http.Request) {
	var item domain.RoutineItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request payload")
		return
	}

	if item.ScheduledDate == "" {
		item.ScheduledDate = time.Now().Format("2006-01-02")
	}
	if item.Status == "" {
		item.Status = domain.StatusPending
	}

	if err := s.routineSvc.CreateItem(r.Context(), &item); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventRoutineUpdated, item)
	}

	respondJSON(w, http.StatusCreated, item)
}

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
	if err := json.NewDecoder(r.Body).Decode(&points); err != nil {
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

func respondJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}
