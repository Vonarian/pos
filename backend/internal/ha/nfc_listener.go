package ha

import (
	"context"
	"encoding/json/v2"
	"errors"
	"log/slog"
	"time"

	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/domain"
	"github.com/pos/backend/internal/service"
)

type TagScannedData struct {
	TagID    string `json:"tag_id"`
	DeviceID string `json:"device_id,omitempty"`
}

func ExtractTagID(eventData []byte) (string, error) {
	// Checks direct object or wrapped {"tag_id": "..."}
	var direct TagScannedData
	if err := json.Unmarshal(eventData, &direct); err == nil && direct.TagID != "" {
		return direct.TagID, nil
	}

	var nested struct {
		Event struct {
			Data TagScannedData `json:"data"`
		} `json:"event"`
	}
	if err := json.Unmarshal(eventData, &nested); err == nil && nested.Event.Data.TagID != "" {
		return nested.Event.Data.TagID, nil
	}

	return "", errors.New("tag_id not found in event payload")
}

func SetupNFCAutomation(
	client *Client,
	routineSvc *service.RoutineService,
	wsHub *ws.Hub,
	routineRepo domain.RoutineRepository,
) {
	client.RegisterEventHandler("tag_scanned", func(eventData []byte) {
		tagID, err := ExtractTagID(eventData)
		if err != nil {
			slog.Warn("Failed to extract tag_id from HA event", "error", err)
			return
		}

		slog.Info("Home Assistant NFC tag scanned", "tag_id", tagID)

		// Find pending routine item with matching nfc_tag
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		today := time.Now().Format("2006-01-02")
		items, err := routineRepo.ListByDate(ctx, today)
		if err != nil {
			slog.Error("Failed to query routines on NFC scan", "error", err)
			return
		}

		for _, item := range items {
			if item.Status == domain.StatusPending && item.Metadata != nil {
				if tagMeta, ok := item.Metadata["nfc_tag"].(string); ok && tagMeta == tagID {
					now := time.Now().UTC()
					if err := routineSvc.CompleteItem(ctx, item.ID, &now); err != nil {
						slog.Error("Failed to complete routine on NFC scan", "item_id", item.ID, "error", err)
					} else {
						slog.Info("Successfully completed routine via NFC scan", "item_id", item.ID, "title", item.Title)
						if wsHub != nil {
							wsHub.BroadcastEvent(ws.EventRoutineCompleted, map[string]string{
								"id":     item.ID,
								"title":  item.Title,
								"source": "ha_nfc",
							})
						}
					}
					break
				}
			}
		}
	})
}
