package data

import (
	"testing"

	"github.com/Blue-Davinci/leadhub-service/internal/validator"
	"github.com/shopspring/decimal"
)

func TestValidateTradeLead(t *testing.T) {
	tests := []struct {
		name      string
		lead      *TradeLead
		wantValid bool
		wantError string
	}{
		{
			name: "Valid trade lead",
			lead: &TradeLead{
				TenantID:    1,
				Title:       "Valid Trade Lead",
				Description: "This is a valid trade lead description",
				Value:       decimal.NewFromFloat(1000.50),
				Status:      "new",
			},
			wantValid: true,
		},
		{
			name: "Empty title should fail",
			lead: &TradeLead{
				TenantID:    1,
				Title:       "",
				Description: "Valid description",
				Value:       decimal.NewFromFloat(1000.50),
				Status:      "new",
			},
			wantValid: false,
			wantError: "title",
		},
		{
			name: "Description too long should fail",
			lead: &TradeLead{
				TenantID:    1,
				Title:       "Valid Title",
				Description: generateLongString(1001), // Over 1000 characters
				Value:       decimal.NewFromFloat(1000.50),
				Status:      "new",
			},
			wantValid: false,
			wantError: "description",
		},
		{
			name: "Zero value should fail",
			lead: &TradeLead{
				TenantID:    1,
				Title:       "Valid Title",
				Description: "Valid description",
				Value:       decimal.Zero,
				Status:      "new",
			},
			wantValid: false,
			wantError: "value",
		},
		{
			name: "Negative value should fail",
			lead: &TradeLead{
				TenantID:    1,
				Title:       "Valid Title",
				Description: "Valid description",
				Value:       decimal.NewFromFloat(-100.00),
				Status:      "new",
			},
			wantValid: false,
			wantError: "value",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := validator.New()
			ValidateTradeLead(v, tt.lead)

			if tt.wantValid && !v.Valid() {
				t.Errorf("Expected valid trade lead, but got validation errors: %v", v.Errors)
			}

			if !tt.wantValid && v.Valid() {
				t.Errorf("Expected validation to fail, but trade lead was valid")
			}

			if !tt.wantValid && tt.wantError != "" {
				if _, exists := v.Errors[tt.wantError]; !exists {
					t.Errorf("Expected validation error for field '%s', but got errors: %v", tt.wantError, v.Errors)
				}
			}
		})
	}
}

func TestValidateTenant(t *testing.T) {
	tests := []struct {
		name      string
		tenant    *Tenant
		wantValid bool
		wantError string
	}{
		{
			name: "Valid tenant",
			tenant: &Tenant{
				Name:         "Valid Company Ltd",
				ContactEmail: "contact@validcompany.com",
				Description:  "A valid company description",
			},
			wantValid: true,
		},
		{
			name: "Empty name should fail",
			tenant: &Tenant{
				Name:         "",
				ContactEmail: "contact@validcompany.com",
				Description:  "A valid company description",
			},
			wantValid: false,
			wantError: "name",
		},
		{
			name: "Invalid email should fail",
			tenant: &Tenant{
				Name:         "Valid Company Ltd",
				ContactEmail: "invalid-email",
				Description:  "A valid company description",
			},
			wantValid: false,
			wantError: "email",
		},
		{
			name: "Description too long should fail",
			tenant: &Tenant{
				Name:         "Valid Company Ltd",
				ContactEmail: "contact@validcompany.com",
				Description:  generateLongString(501), // Over 500 characters
			},
			wantValid: false,
			wantError: "description",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := validator.New()
			ValidateTenant(v, tt.tenant)

			if tt.wantValid && !v.Valid() {
				t.Errorf("Expected valid tenant, but got validation errors: %v", v.Errors)
			}

			if !tt.wantValid && v.Valid() {
				t.Errorf("Expected validation to fail, but tenant was valid")
			}

			if !tt.wantValid && tt.wantError != "" {
				// For email, the error key is "email", but field might be "contact_email"
				if tt.wantError == "email" {
					if _, exists := v.Errors["email"]; !exists {
						t.Errorf("Expected validation error for email field, but got errors: %v", v.Errors)
					}
				} else {
					if _, exists := v.Errors[tt.wantError]; !exists {
						t.Errorf("Expected validation error for field '%s', but got errors: %v", tt.wantError, v.Errors)
					}
				}
			}
		})
	}
}

// Helper function to generate a string of specified length
func generateLongString(length int) string {
	result := make([]byte, length)
	for i := range result {
		result[i] = 'a'
	}
	return string(result)
}

// Test that demonstrates the security benefits of your decimal usage
func TestTradeLeadDecimalPrecision(t *testing.T) {
	// This test shows that your use of shopspring/decimal prevents
	// floating point precision issues that could cause financial discrepancies

	lead := &TradeLead{
		TenantID:    1,
		Title:       "High Value Trade",
		Description: "Trade with precise monetary value",
		Value:       decimal.RequireFromString("999999.99"), // Precise decimal
		Status:      "new",
	}

	v := validator.New()
	ValidateTradeLead(v, lead)

	if !v.Valid() {
		t.Errorf("Valid high-precision decimal should pass validation, got errors: %v", v.Errors)
	}

	// Verify decimal precision is maintained
	expected := "999999.99"
	if lead.Value.String() != expected {
		t.Errorf("Decimal precision not maintained: expected %s, got %s", expected, lead.Value.String())
	}

	t.Log("FiINANCIAL SECURITY: Decimal precision maintained - prevents rounding errors in financial calculations")
}
