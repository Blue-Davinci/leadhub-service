package main

import (
	"database/sql"
	"expvar"
	"flag"
	"fmt"
	"os"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/Blue-Davinci/leadhub-service/internal/data"
	"github.com/Blue-Davinci/leadhub-service/internal/database"
	"github.com/Blue-Davinci/leadhub-service/internal/logger"
	"github.com/Blue-Davinci/leadhub-service/internal/mailer"
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
	api  struct {
		name    string
		author  string
		version string
	}
	db struct {
		dsn          string
		maxOpenConns int
		maxIdleConns int
		maxIdleTime  string
	}
	cors struct {
		trustedOrigins []string
	}
	url struct {
		activationURL     string
		authenticationURL string
	}
	smtp struct {
		host     string
		port     int
		username string
		password string
		sender   string
	}
	limiter struct {
		rps     float64
		burst   int
		enabled bool
	}
}

type application struct {
	config config
	logger *zap.Logger
	wg     sync.WaitGroup
	models data.Models
	mailer mailer.Mailer
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
	// api configuration
	flag.StringVar(&cfg.api.name, "api-name", "LeadHUb", "API Name")
	flag.StringVar(&cfg.api.author, "api-author", "Blue-Davinci", "API Author")
	// Our SMTP flags with given defaults.
	flag.StringVar(&cfg.smtp.host, "smtp-host", os.Getenv("LEADHUB_SMTP_HOST"), "SMTP server hostname")
	flag.IntVar(&cfg.smtp.port, "smtp-port", 587, "SMTP server port")
	flag.StringVar(&cfg.smtp.username, "smtp-username", os.Getenv("LEADHUB_SMTP_USERNAME"), "SMTP server username")
	flag.StringVar(&cfg.smtp.password, "smtp-password", os.Getenv("LEADHUB_SMTP_PASSWORD"), "SMTP server password")
	flag.StringVar(&cfg.smtp.sender, "smtp-sender", os.Getenv("LEADHUB_SMTP_SENDER"), "SMTP sender email address")
	// limiter cinfugs
	flag.Float64Var(&cfg.limiter.rps, "limiter-rps", 5, "Rate limiter maximum requests per second")
	flag.IntVar(&cfg.limiter.burst, "limiter-burst", 10, "Rate limiter maximum burst")
	flag.BoolVar(&cfg.limiter.enabled, "limiter-enabled", true, "Enable rate limiter")
	// URL configuration
	flag.StringVar(&cfg.url.activationURL, "activation-url", "http://localhost:4000/v1/api/activated/token=", "Activation URL for user registration")
	flag.StringVar(&cfg.url.authenticationURL, "authentication-url", "http://localhost:4000/v1/api", "Authentication URL for user login")
	// CORS configuration
	flag.Func("cors-trusted-origins", "Trusted CORS origins (space separated)", func(val string) error {
		cfg.cors.trustedOrigins = strings.Fields(val)
		return nil

	})
	// Parse the flags
	flag.Parse()

	// Construct DSN from individual components if not provided directly
	if cfg.db.dsn == "" {
		dbUser := getEnvDefault("DB_USER", "leadhub")
		dbPassword := getEnvDefault("DB_PASSWORD", "test")
		dbHost := getEnvDefault("DB_HOST", "localhost")
		dbPort := getEnvDefault("DB_PORT", "5432")
		dbName := getEnvDefault("DB_NAME", "leadhub")
		dbSSLMode := getEnvDefault("DB_SSLMODE", "disable")

		cfg.db.dsn = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
			dbUser, dbPassword, dbHost, dbPort, dbName, dbSSLMode)

		logger.Info("Constructed DSN from individual components",
			zap.String("host", dbHost),
			zap.String("port", dbPort),
			zap.String("database", dbName))
	}

	// Load additional configuration from environment variables
	loadConfig(&cfg)
	// create our connection pull
	db, err := openDB(cfg)
	if err != nil {
		logger.Fatal(err.Error(), zap.String("dsn", cfg.db.dsn))
	}
	// Init our exp metrics variables for server metrics.
	publishMetrics()
	// instantiate the application struct for dependency injection
	app := &application{
		config: cfg,
		logger: logger,
		models: data.NewModels(db),
		mailer: mailer.New(cfg.smtp.host, cfg.smtp.port, cfg.smtp.username, cfg.smtp.password, cfg.smtp.sender),
	}
	// Print the version information
	logger.Info("Starting LeadHub Service",
		zap.String("version", version),
		zap.String("env", app.config.env),
		zap.Int("port", app.config.port),
	)
	err = app.server()
	if err != nil {
		logger.Fatal("Error while starting server.", zap.String("error", err.Error()))
	}
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

// publishMetrics sets up the expvar variables for the application
// It sets the version, the number of active goroutines, and the current Unix timestamp.
func publishMetrics() {
	expvar.NewString("version").Set(version)
	// Publish the number of active goroutines.
	expvar.Publish("goroutines", expvar.Func(func() any {
		return runtime.NumGoroutine()
	}))
	// Publish the current Unix timestamp.
	expvar.Publish("timestamp", expvar.Func(func() any {
		return time.Now().Unix()
	}))
}

// loadConfig loads additional configuration values from environment variables
func loadConfig(cfg *config) {
	// Set API configuration
	cfg.api.name = getEnvDefault("LEADHUB_API_NAME", "LEADHUB API")
	cfg.api.author = getEnvDefault("LEADHUB_API_AUTHOR", "Blue-Davinci")
	cfg.api.version = version

	// Set CORS trusted origins (comma-separated)
	originsStr := getEnvDefault("LEADHUB_CORS_TRUSTED_ORIGINS", "http://localhost:3000,http://localhost:8080")
	if originsStr != "" {
		cfg.cors.trustedOrigins = strings.Split(originsStr, ",")
		// Trim spaces from each origin
		for i, origin := range cfg.cors.trustedOrigins {
			cfg.cors.trustedOrigins[i] = strings.TrimSpace(origin)
		}
	}
}

// getEnvDefault gets an environment variable with a default fallback
func getEnvDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
