package ha

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Config struct {
	Host  string
	Token string
}

type Client struct {
	cfg       Config
	conn      *websocket.Conn
	mu        sync.Mutex
	msgID     int
	handlers  map[string]func(eventData []byte)
	isClosing bool
}

func NewClient(cfg Config) *Client {
	return &Client{
		cfg:      cfg,
		handlers: make(map[string]func(eventData []byte)),
	}
}

func (c *Client) RegisterEventHandler(eventType string, handler func(eventData []byte)) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.handlers[eventType] = handler
}

func (c *Client) ConnectAndListen(ctx context.Context) error {
	if c.cfg.Host == "" || c.cfg.Token == "" {
		slog.Info("Home Assistant host or token not configured, skipping HA connector")
		return nil
	}

	wsURL := fmt.Sprintf("ws://%s/api/websocket", c.cfg.Host)
	slog.Info("Connecting to Home Assistant WebSocket", "url", wsURL)

	conn, _, err := websocket.DefaultDialer.DialContext(ctx, wsURL, nil)
	if err != nil {
		return fmt.Errorf("failed to dial HA websocket: %w", err)
	}

	c.mu.Lock()
	c.conn = conn
	c.isClosing = false
	c.mu.Unlock()

	// 1. Initial auth phase
	var authReq struct {
		Type string `json:"type"`
	}
	if err := conn.ReadJSON(&authReq); err != nil {
		return fmt.Errorf("failed to read HA auth challenge: %w", err)
	}

	if authReq.Type != "auth_required" {
		return fmt.Errorf("unexpected HA initial message: %s", authReq.Type)
	}

	// Send auth token
	authMsg := map[string]string{
		"type":         "auth",
		"access_token": c.cfg.Token,
	}
	if err := conn.WriteJSON(authMsg); err != nil {
		return fmt.Errorf("failed to send HA auth token: %w", err)
	}

	var authResp struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	}
	if err := conn.ReadJSON(&authResp); err != nil {
		return fmt.Errorf("failed to read HA auth response: %w", err)
	}

	if authResp.Type != "auth_ok" {
		return fmt.Errorf("HA authentication failed: %s", authResp.Message)
	}
	slog.Info("Connected and authenticated with Home Assistant successfully")

	// 2. Subscribe to tag_scanned events
	c.mu.Lock()
	c.msgID++
	subMsg := map[string]any{
		"id":         c.msgID,
		"type":       "subscribe_events",
		"event_type": "tag_scanned",
	}
	_ = conn.WriteJSON(subMsg)
	c.mu.Unlock()

	// 3. Message pump
	for {
		select {
		case <-ctx.Done():
			c.Close()
			return nil
		default:
			_, msg, err := conn.ReadMessage()
			if err != nil {
				c.mu.Lock()
				closing := c.isClosing
				c.mu.Unlock()
				if closing {
					return nil
				}
				slog.Warn("Home Assistant websocket disconnected, will retry", "error", err)
				return err
			}

			c.dispatchMessage(msg)
		}
	}
}

type EventWrapper struct {
	Type  string `json:"type"`
	Event struct {
		EventType string          `json:"event_type"`
		Data      json.RawMessage `json:"data"`
	} `json:"event"`
}

func (c *Client) dispatchMessage(msg []byte) {
	var ev EventWrapper
	if err := json.Unmarshal(msg, &ev); err != nil {
		return
	}

	if ev.Type == "event" {
		c.mu.Lock()
		handler, ok := c.handlers[ev.Event.EventType]
		c.mu.Unlock()

		if ok && handler != nil {
			handler(ev.Event.Data)
		}
	}
}

func (c *Client) Close() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.isClosing = true
	if c.conn != nil {
		_ = c.conn.Close()
	}
}

func (c *Client) SendRESTService(ctx context.Context, domain, service string, payload map[string]any) error {
	if c.cfg.Host == "" || c.cfg.Token == "" {
		return nil
	}

	url := fmt.Sprintf("http://%s/api/services/%s/%s", c.cfg.Host, domain, service)
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal service payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(data))
	if err != nil {
		return fmt.Errorf("failed to create service request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.cfg.Token)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute HA service call: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("HA service call returned HTTP status %d", resp.StatusCode)
	}

	return nil
}
