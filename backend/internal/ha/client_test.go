package ha_test

import (
	"testing"

	"github.com/pos/backend/internal/ha"
)

func TestExtractTagIDDirect(t *testing.T) {
	raw := []byte(`{"tag_id": "pill_shelf_nfc_99", "device_id": "phone_pixel"}`)
	tagID, err := ha.ExtractTagID(raw)
	if err != nil {
		t.Fatalf("expected successful tag extraction, got err: %v", err)
	}

	if tagID != "pill_shelf_nfc_99" {
		t.Errorf("expected tag pill_shelf_nfc_99, got %s", tagID)
	}
}

func TestExtractTagIDNested(t *testing.T) {
	raw := []byte(`{
		"event": {
			"data": {
				"tag_id": "workout_bag_tag",
				"device_id": "phone_pixel"
			}
		}
	}`)

	tagID, err := ha.ExtractTagID(raw)
	if err != nil {
		t.Fatalf("expected successful nested tag extraction, got err: %v", err)
	}

	if tagID != "workout_bag_tag" {
		t.Errorf("expected tag workout_bag_tag, got %s", tagID)
	}
}

func TestBuildActionableNotification(t *testing.T) {
	actions := []ha.ActionButton{
		{Action: "COMPLETE_ROUTINE_123", Title: "Done"},
		{Action: "SKIP_ROUTINE_123", Title: "Skip"},
	}

	payload := ha.BuildActionableNotification("Bedtime Stack Alert", "1 item remaining", actions)

	if payload["title"] != "Bedtime Stack Alert" {
		t.Errorf("expected title Bedtime Stack Alert, got %v", payload["title"])
	}

	dataMap, ok := payload["data"].(map[string]any)
	if !ok {
		t.Fatalf("expected data object in payload")
	}

	actionsList, ok := dataMap["actions"].([]map[string]string)
	if !ok || len(actionsList) != 2 {
		t.Fatalf("expected 2 actions in payload")
	}

	if actionsList[0]["action"] != "COMPLETE_ROUTINE_123" {
		t.Errorf("expected first action COMPLETE_ROUTINE_123, got %s", actionsList[0]["action"])
	}
}
