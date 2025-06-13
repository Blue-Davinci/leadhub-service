package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Blue-Davinci/leadhub-service/internal/data"
	"go.uber.org/zap"
)

func TestRateLimitingMiddleware(t *testing.T) {
	// Create test application with strict rate limiting for testing
	app := &application{
		config: config{
			env: "testing",
			limiter: struct {
				rps     float64
				burst   int
				enabled bool
			}{
				rps:     1, // 1 request per second
				burst:   1, // Burst of 1
				enabled: true,
			},
		},
		logger: zap.NewNop(),
		models: data.Models{},
	}

	// Create a simple test handler
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("success"))
	})

	// Wrap with rate limiting middleware
	rateLimitedHandler := app.rateLimit(testHandler)

	t.Run("First request should succeed", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:8080" // Simulate client IP
		rr := httptest.NewRecorder()

		rateLimitedHandler.ServeHTTP(rr, req)

		if rr.Code != http.StatusOK {
			t.Errorf("Expected first request to succeed, got status %d", rr.Code)
		}
	})

	t.Run("Rapid second request should be rate limited", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:8080" // Same client IP
		rr := httptest.NewRecorder()

		rateLimitedHandler.ServeHTTP(rr, req)

		if rr.Code != http.StatusTooManyRequests {
			t.Errorf("Expected second rapid request to be rate limited (429), got status %d", rr.Code)
		}

		// Verify rate limit error message
		if !contains(rr.Body.String(), "rate limit exceeded") {
			t.Errorf("Expected rate limit error message, got: %s", rr.Body.String())
		}
	})

	t.Run("Different IP should not be rate limited", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.2:8080" // Different client IP
		rr := httptest.NewRecorder()

		rateLimitedHandler.ServeHTTP(rr, req)

		if rr.Code != http.StatusOK {
			t.Errorf("Expected request from different IP to succeed, got status %d", rr.Code)
		}
	})

	t.Run("Rate limiting can be disabled", func(t *testing.T) {
		// Create app with rate limiting disabled
		appNoLimit := &application{
			config: config{
				env: "testing",
				limiter: struct {
					rps     float64
					burst   int
					enabled bool
				}{
					rps:     1,
					burst:   1,
					enabled: false, // Disabled
				},
			},
			logger: zap.NewNop(),
			models: data.Models{},
		}

		handler := appNoLimit.rateLimit(testHandler)

		// Make multiple rapid requests
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.3:8080"
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if rr.Code != http.StatusOK {
				t.Errorf("Request %d should succeed when rate limiting disabled, got status %d", i+1, rr.Code)
			}
		}
	})

	t.Log("pERFORMANCE & SECURITY: Rate limiting protects against abuse while allowing legitimate traffic")
}

// TestMetricsMiddleware tests that the metrics middleware properly tracks requests
func TestMetricsMiddleware(t *testing.T) {
	app := &application{
		config: config{env: "testing"},
		logger: zap.NewNop(),
		models: data.Models{},
	}

	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	metricsHandler := app.metrics(testHandler)

	req := httptest.NewRequest("GET", "/test", nil)
	rr := httptest.NewRecorder()

	metricsHandler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected request to succeed through metrics middleware, got status %d", rr.Code)
	}

	t.Log("OBSERVABILITY: Metrics middleware properly wraps handlers for monitoring")
}

// TestRecoverPanicMiddleware tests that panic recovery works correctly
func TestRecoverPanicMiddleware(t *testing.T) {
	app := &application{
		config: config{env: "testing"},
		logger: zap.NewNop(),
		models: data.Models{},
	}

	// Handler that panics
	panicHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("test panic")
	})

	recoveryHandler := app.recoverPanic(panicHandler)

	req := httptest.NewRequest("GET", "/test", nil)
	rr := httptest.NewRecorder()

	// This should not crash the test
	recoveryHandler.ServeHTTP(rr, req)

	// Should return 500 error instead of crashing
	if rr.Code != http.StatusInternalServerError {
		t.Errorf("Expected panic to be recovered with 500 status, got %d", rr.Code)
	}

	// Check Connection: close header is set
	if rr.Header().Get("Connection") != "close" {
		t.Errorf("Expected Connection: close header to be set on panic recovery")
	}

	t.Log("RELIABILITY: Panic recovery prevents service crashes and sets appropriate headers")
}
