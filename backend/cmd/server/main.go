package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/pos/backend/internal/api/middleware"
	"github.com/pos/backend/internal/api/rest"
	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/config"
	"github.com/pos/backend/internal/repository/postgres"
	"github.com/pos/backend/internal/service"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	cfg := config.Load()
	slog.Info("Starting Personal Operating System (POS) daemon", "port", cfg.Port)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	pgCfg := postgres.Config{
		Host:     cfg.PostgresHost,
		Port:     cfg.PostgresPort,
		User:     cfg.PostgresUser,
		Password: cfg.PostgresPass,
		DBName:   cfg.PostgresDB,
		SSLMode:  cfg.PostgresSSL,
	}

	db, err := postgres.NewDB(ctx, pgCfg.DSN())
	if err != nil {
		slog.Warn("PostgreSQL connection could not be established; ensure PostgreSQL is running for persistent state", "error", err)
	} else {
		defer db.Close()
		slog.Info("Connected to PostgreSQL successfully")
	}

	// Initialize repositories and services
	var routineRepo *postgres.RoutineRepo
	var metricRepo *postgres.MetricRepo
	if db != nil {
		routineRepo = postgres.NewRoutineRepository(db)
		metricRepo = postgres.NewMetricRepository(db)
	}

	wsHub := ws.NewHub()
	go wsHub.Run()

	var routineSvc *service.RoutineService
	var metricSvc *service.MetricService
	var cronSvc *service.CronService

	if routineRepo != nil && metricRepo != nil {
		routineSvc = service.NewRoutineService(routineRepo)
		metricSvc = service.NewMetricService(metricRepo)
		cronSvc = service.NewCronService(routineRepo)

		// Start midnight reset cron
		go cronSvc.StartMidnightTicker(ctx)
	}

	server := rest.NewServer(routineSvc, metricSvc, cronSvc, wsHub)
	handler := middleware.EnableCORS(server.Routes())

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info("HTTP and WebSocket server listening", "addr", httpServer.Addr)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("HTTP server failed", "error", err)
		}
	}()

	// Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("Shutting down POS daemon...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		slog.Error("Server forced to shutdown", "error", err)
	}

	slog.Info("POS daemon stopped cleanly")
}
