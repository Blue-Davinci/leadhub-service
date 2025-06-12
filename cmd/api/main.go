package main

import (
	"database/sql"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/Blue-Davinci/leadhub-service/internal/database"
	"github.com/Blue-Davinci/leadhub-service/internal/logger"
	"github.com/Blue-Davinci/leadhub-service/internal/vcs"
	_ "github.com/lib/pq"
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
	cors struct {
		trustedOrigins []string
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
	// CORS configuration
	flag.Func("cors-trusted-origins", "Trusted CORS origins (space separated)", func(val string) error {
		cfg.cors.trustedOrigins = strings.Fields(val)
		return nil

	})
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

// openDB() opens a new database connection using the provided configuration.
// It returns a pointer to the sql.DB connection pool and an error value.
func openDB(cfg config) (*database.Queries, error) {
	db, err := sql.Open("postgres", cfg.db.dsn)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(cfg.db.maxOpenConns)
	db.SetMaxIdleConns(cfg.db.maxIdleConns)
	duration, err := time.ParseDuration(cfg.db.maxIdleTime)
	if err != nil {
		return nil, err
	}
	db.SetConnMaxIdleTime(duration)
	// Use ping to establish new conncetions
	err = db.Ping()
	if err != nil {
		return nil, err
	}
	queries := database.New(db)
	return queries, nil
}
