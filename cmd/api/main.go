package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/Blue-Davinci/leadhub-service/internal/logger"
	"github.com/Blue-Davinci/leadhub-service/internal/vcs"
	"go.uber.org/zap"
)

// a quick variable to hold our version. ToDo: Change this.
var (
	version = vcs.Version()
)

type config struct {
	port int
	env  string
	db   struct {
		dsn          string
		maxOpenConns int
		maxIdleConns int
		maxIdleTime  string
	}
}

type application struct {
	config config
	logger *zap.Logger
}

func main() {
	logger, err := logger.InitJSONLogger()
	if err != nil {
		fmt.Println("Error initializing logger, exiting...")
		return
	}

	// config
	var cfg config
	// Port & env
	flag.IntVar(&cfg.port, "port", 4000, "API server port")
	flag.StringVar(&cfg.env, "env", "development", "Environment (development|staging|production)")
	// Database configuration
	flag.StringVar(&cfg.db.dsn, "db-dsn", os.Getenv("LEADHUB_DB_DSN"), "PostgreSQL DSN")
	flag.IntVar(&cfg.db.maxOpenConns, "db-max-open-conns", 25, "PostgreSQL max open connections")
	flag.IntVar(&cfg.db.maxIdleConns, "db-max-idle-conns", 25, "PostgreSQL max idle connections")
	flag.StringVar(&cfg.db.maxIdleTime, "db-max-idle-time", "15m", "PostgreSQL max connection idle time")
	// Parse the flags
	flag.Parse()

	app := &application{
		config: cfg,
		logger: logger,
	}
	// log some info
	app.logger.Info("Starting LeadHub Service",
		zap.String("version", version),
		zap.Int("port", app.config.port),
		zap.String("env", app.config.env),
	)
}
