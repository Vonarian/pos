package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port         int
	PostgresHost string
	PostgresPort int
	PostgresUser string
	PostgresPass string
	PostgresDB   string
	PostgresSSL  string
	HAHost       string
	HAToken      string
}

func Load() *Config {
	port := 8080
	if p := os.Getenv("PORT"); p != "" {
		if val, err := strconv.Atoi(p); err == nil {
			port = val
		}
	}

	pgPort := 5432
	if p := os.Getenv("POSTGRES_PORT"); p != "" {
		if val, err := strconv.Atoi(p); err == nil {
			pgPort = val
		}
	}

	pgHost := os.Getenv("POSTGRES_HOST")
	if pgHost == "" {
		pgHost = "localhost"
	}
	pgUser := os.Getenv("POSTGRES_USER")
	if pgUser == "" {
		pgUser = "postgres"
	}
	pgPass := os.Getenv("POSTGRES_PASSWORD")
	if pgPass == "" {
		pgPass = "postgres"
	}
	pgDB := os.Getenv("POSTGRES_DB")
	if pgDB == "" {
		pgDB = "pos_db"
	}
	pgSSL := os.Getenv("POSTGRES_SSLMODE")
	if pgSSL == "" {
		pgSSL = "disable"
	}

	return &Config{
		Port:         port,
		PostgresHost: pgHost,
		PostgresPort: pgPort,
		PostgresUser: pgUser,
		PostgresPass: pgPass,
		PostgresDB:   pgDB,
		PostgresSSL:  pgSSL,
		HAHost:       os.Getenv("HA_HOST"),
		HAToken:      os.Getenv("HA_TOKEN"),
	}
}
