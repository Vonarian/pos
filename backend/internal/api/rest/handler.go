package rest

import (
	"encoding/json/v2"
	"net/http"
	"time"

	"github.com/pos/backend/internal/api/ws"
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

func respondJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.MarshalWrite(w, payload)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}
