package rest

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/domain"
)

type SyncPushRequest struct {
	Routines []domain.RoutineItem     `json:"routines"`
	Metrics  []domain.HealthDataPoint `json:"metrics"`
}

type SyncPushResponse struct {
	SyncedRoutines int    `json:"synced_routines"`
	SyncedMetrics  int    `json:"synced_metrics"`
	SyncedAt       string `json:"synced_at"`
}

type SyncPullResponse struct {
	Routines []domain.RoutineItem     `json:"routines"`
	Metrics  []domain.HealthDataPoint `json:"metrics"`
	ServerTime string                 `json:"server_time"`
}

func (s *Server) handleSyncPush(w http.ResponseWriter, r *http.Request) {
	var req SyncPushRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid sync push payload")
		return
	}

	if len(req.Routines) > 0 {
		if err := s.routineSvc.SyncBatch(r.Context(), req.Routines); err != nil {
			respondError(w, http.StatusInternalServerError, "failed to sync routines: "+err.Error())
			return
		}
	}

	if len(req.Metrics) > 0 {
		if err := s.metricSvc.IngestMetrics(r.Context(), req.Metrics); err != nil {
			respondError(w, http.StatusInternalServerError, "failed to sync metrics: "+err.Error())
			return
		}
	}

	now := time.Now().UTC()
	if s.wsHub != nil {
		s.wsHub.BroadcastEvent(ws.EventQuadrantRefresh, map[string]any{
			"routines_count": len(req.Routines),
			"metrics_count":  len(req.Metrics),
			"synced_at":      now.Format(time.RFC3339),
		})
	}

	respondJSON(w, http.StatusOK, SyncPushResponse{
		SyncedRoutines: len(req.Routines),
		SyncedMetrics:  len(req.Metrics),
		SyncedAt:       now.Format(time.RFC3339),
	})
}

func (s *Server) handleSyncPull(w http.ResponseWriter, r *http.Request) {
	sinceStr := r.URL.Query().Get("since")
	var since time.Time
	if sinceStr != "" {
		parsed, err := time.Parse(time.RFC3339, sinceStr)
		if err == nil {
			since = parsed
		}
	}

	routines, err := s.routineSvc.ListSince(r.Context(), since)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to pull routines: "+err.Error())
		return
	}

	metrics, err := s.metricSvc.ListSince(r.Context(), since)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to pull metrics: "+err.Error())
		return
	}

	if routines == nil {
		routines = []domain.RoutineItem{}
	}
	if metrics == nil {
		metrics = []domain.HealthDataPoint{}
	}

	respondJSON(w, http.StatusOK, SyncPullResponse{
		Routines:   routines,
		Metrics:    metrics,
		ServerTime: time.Now().UTC().Format(time.RFC3339),
	})
}
