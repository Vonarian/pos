package rest

import (
	"encoding/json/v2"
	"net/http"
	"time"

	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/domain"
)

type ActionRequest struct {
	ID          string     `json:"id"`
	CompletedAt *time.Time `json:"completed_at,omitzero"`
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

func (s *Server) handleCompleteRoutine(w http.ResponseWriter, r *http.Request) {
	var req ActionRequest
	if err := json.UnmarshalRead(r.Body, &req); err != nil || req.ID == "" {
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
	if err := json.UnmarshalRead(r.Body, &req); err != nil || req.ID == "" {
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
	if err := json.UnmarshalRead(r.Body, &req); err != nil || req.ID == "" {
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
	if err := json.UnmarshalRead(r.Body, &req); err != nil || req.ID == "" {
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
	if err := json.UnmarshalRead(r.Body, &item); err != nil {
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
