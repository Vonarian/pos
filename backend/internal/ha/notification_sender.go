package ha

import (
	"context"
	"fmt"
)

type ActionButton struct {
	Action string `json:"action"` // e.g. "COMPLETE_ROUTINE_<id>"
	Title  string `json:"title"`  // e.g. "Done"
}

type NotificationPayload struct {
	Title   string         `json:"title"`
	Message string         `json:"message"`
	Data    map[string]any `json:"data"`
}

func BuildActionableNotification(title, message string, actions []ActionButton) map[string]any {
	haActions := make([]map[string]string, 0, len(actions))
	for _, a := range actions {
		haActions = append(haActions, map[string]string{
			"action": a.Action,
			"title":  a.Title,
		})
	}

	return map[string]any{
		"title":   title,
		"message": message,
		"data": map[string]any{
			"actions": haActions,
			"push": map[string]any{
				"interruption-level": "time-sensitive",
			},
		},
	}
}

func SendWindowClosingAlert(ctx context.Context, client *Client, serviceName string, windowName string, pendingCount int) error {
	title := fmt.Sprintf("POS: %s Window Closing Soon", windowName)
	message := fmt.Sprintf("You still have %d daily habits pending in this window.", pendingCount)

	actions := []ActionButton{
		{Action: "OPEN_POS_APP", Title: "Open POS"},
	}

	payload := BuildActionableNotification(title, message, actions)
	return client.SendRESTService(ctx, "notify", serviceName, payload)
}
