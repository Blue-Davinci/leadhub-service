package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Blue-Davinci/leadhub-service/internal/data"
	"go.uber.org/zap"
)

func TestHealthcheckHandler(t *testing.T) {
	// Create a test application
	app := &application{
		config: config{
			env: "testing",
		},
		logger: zap.NewNop(),  // No-op logger for tests
		models: data.Models{}, // Empty models since we don't check DB
	}

	// Create a request to the health endpoint
	req, err := http.NewRequest("GET", "/v1/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	// Create a ResponseRecorder to record the response
	rr := httptest.NewRecorder()

	// Call the handler
	app.healthcheckHandler(rr, req)

	// Check the status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	// Check that response contains expected fields
	expected := `"available"`
	if !contains(rr.Body.String(), expected) {
		t.Errorf("handler returned unexpected body: got %v want it to contain %v", rr.Body.String(), expected)
	}

	// Check environment field
	expectedEnv := `"testing"`
	if !contains(rr.Body.String(), expectedEnv) {
		t.Errorf("handler returned unexpected environment: got %v want it to contain %v", rr.Body.String(), expectedEnv)
	}

	// Check content type
	expected_content_type := "application/json"
	if ctype := rr.Header().Get("Content-Type"); ctype != expected_content_type {
		t.Errorf("handler returned wrong content type: got %v want %v", ctype, expected_content_type)
	}
}

// Helper function to check if a string contains a substring
func contains(s, substr string) bool {
	// Use strings.Contains for proper substring matching
	return strings.Contains(s, substr)
}
