package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"golang.org/x/sync/errgroup"

	"github.com/pos/backend/internal/api/middleware"
	"github.com/pos/backend/internal/api/rest"
	"github.com/pos/backend/internal/api/ws"
	"github.com/pos/backend/internal/config"
	"github.com/pos/backend/internal/repository/postgres"
	"github.com/pos/backend/internal/service"
)

var (
	Version   = "1.0.0-dev"
	Commit    = "none"
	BuildDate = "unknown"
)

func initDB(ctx context.Context, cfg *config.Config) *postgres.DB {
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
		slog.Warn("PostgreSQL connection could not be established", "error", err)
		return nil
	}
	slog.Info("Connected to PostgreSQL successfully")
	return db
}

func startHTTPServer(port int, handler http.Handler) *http.Server {
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", port),
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
	go func() {
		slog.Info("HTTP and WebSocket server listening", "addr", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("HTTP server failed", "error", err)
		}
	}()
	return srv
}

func waitForShutdown(cancel context.CancelFunc, srv *http.Server, eg *errgroup.Group) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("Shutting down POS daemon...")
	cancel()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		slog.Error("Server forced to shutdown", "error", err)
	}

	if err := eg.Wait(); err != nil && !errors.Is(err, context.Canceled) {
		slog.Error("Error waiting for background workers", "error", err)
	}

	slog.Info("POS daemon stopped cleanly")
}

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo})))
	cfg := config.Load()
	slog.Info("Starting POS daemon", "version", Version, "port", cfg.Port)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	db := initDB(ctx, cfg)
	if db != nil {
		defer db.Close()
	}

	eg, gCtx := errgroup.WithContext(ctx)
	wsHub := ws.NewHub()
	eg.Go(func() error { return wsHub.Run(gCtx) })

	var rSvc *service.RoutineService
	var mSvc *service.MetricService
	var cSvc *service.CronService
	if db != nil {
		rRepo := postgres.NewRoutineRepository(db)
		mRepo := postgres.NewMetricRepository(db)
		rSvc = service.NewRoutineService(rRepo)
		mSvc = service.NewMetricService(mRepo)
		cSvc = service.NewCronService(rRepo)
		eg.Go(func() error {
			cSvc.StartMidnightTicker(gCtx)
			return nil
		})
	}

	server := rest.NewServer(rSvc, mSvc, cSvc, wsHub)
	server.SetVersion(Version)
	httpServer := startHTTPServer(cfg.Port, middleware.EnableCORS(server.Routes()))

	waitForShutdown(cancel, httpServer, eg)
}
