package data

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/Blue-Davinci/leadhub-service/internal/database"
	"github.com/Blue-Davinci/leadhub-service/internal/validator"
	"github.com/shopspring/decimal"
)

type TradeLeadModel struct {
	DB *database.Queries
}

const (
	DefaultLeadManagerDBContextTimeout = 5 * time.Second
)

var (
	ErrInvalidTenantReference = errors.New("invalid tenant reference")
	ErrInvalidTradeLeadStatus = errors.New("invalid trade lead status")
)

// TradeLead represents a trade lead in the system.
type TradeLead struct {
	ID          int64           `json:"id"`
	TenantID    int64           `json:"tenant_id"`
	Title       string          `json:"title"`
	Description string          `json:"description"`
	Status      string          `json:"status"`
	Value       decimal.Decimal `json:"value"`
	Version     int32           `json:"version"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}
type TradeStats struct {
	TotalLeads         decimal.Decimal `json:"total_leads"`
	TotalVerifiedValue decimal.Decimal `json:"total_verified_value"`
	VerifiedLeads      decimal.Decimal `json:"verified_leads"`
}

// ValidateTradeLead validates the fields of a TradeLead.
func ValidateTradeLead(v *validator.Validator, lead *TradeLead) {
	// should validate tenant ID, title, description, and value
	v.Check(lead.Title != "", "title", "must be provided")
	v.Check(len(lead.Description) <= 1000, "description", "must not be more than 1000 characters long")
	v.Check(lead.Value.GreaterThan(decimal.Zero), "value", "must be a non-negative or non-zero number")
}

// CreateTradeLead() creates a new trade lead in the database.
// we accept the tenant_id, and a *TradeLead struct as input.
func (m TradeLeadModel) CreateTradeLead(tenantID int64, tenantLead *TradeLead) error {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// create the trade lead in the database
	newLead, err := m.DB.CreateTradeLead(ctx, database.CreateTradeLeadParams{
		TenantID:    tenantID,
		Title:       tenantLead.Title,
		Description: sql.NullString{String: tenantLead.Description, Valid: true},
		Value:       tenantLead.Value.String(),
	})
	if err != nil {
		switch {
		case strings.Contains(err.Error(), "trade_leads_tenant_id_fkey"):
			return ErrInvalidTenantReference
		case strings.Contains(err.Error(), "trade_leads_status_check"):
			return ErrInvalidTradeLeadStatus
		default:
			return err
		}
	}

	// Populate the trade lead struct with the new data
	tenantLead.ID = newLead.ID
	tenantLead.TenantID = newLead.TenantID
	tenantLead.Version = newLead.Version
	tenantLead.CreatedAt = newLead.CreatedAt
	tenantLead.UpdatedAt = newLead.UpdatedAt
	// we are good to go
	return nil
}

// GetTradeLeadByID() retrieves a trade lead by its ID from the database.
func (m TradeLeadModel) GetTradeLeadByID(id int64) (*TradeLead, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// get trade lead by ID
	lead, err := m.DB.GetTradeLeadByID(ctx, id)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrGeneralRecordNotFound
		default:
			return nil, err
		}
	}
	// populate the trade lead struct
	tradeLead := populateTradeLeads(lead)
	// return the trade lead
	return tradeLead, nil
}

// GetAllLeadsByTenantID() retrieves all trade leads for a specific tenant ID from the database.
// It supports both filtering and pagination.
func (m TradeLeadModel) GetAllLeadsByTenantID(tenantID int64, name string, filters Filters) ([]*TradeLead, Metadata, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// get all trade leads by tenant ID
	leads, err := m.DB.GetAllLeadsByTenantID(ctx, database.GetAllLeadsByTenantIDParams{
		TenantID: tenantID,
		Column2:  name,
		Limit:    filters.limitInt32(),
		Offset:   filters.offsetInt32(),
	})
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, Metadata{}, ErrGeneralRecordNotFound
		default:
			return nil, Metadata{}, err
		}
	}
	// chekc the length of leads
	if len(leads) == 0 {
		return nil, Metadata{}, ErrGeneralRecordNotFound
	}
	// populate the leads slice
	leadRows := []*TradeLead{}
	totalRows := 0
	for _, leadRow := range leads {
		totalRows = int(leadRow.TotalCount)
		leadRows = append(leadRows, populateTradeLeads(leadRow))
	}
	// metadata
	metadata := calculateMetadata(totalRows, filters.Page, filters.PageSize)
	// return
	return leadRows, metadata, nil
}

// AdminGetAllTradeLeads() retrieves all trade leads from the database.
func (m TradeLeadModel) AdminGetAllTradeLeads(name string, filters Filters) ([]*TradeLead, Metadata, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// get all trade leads
	leads, err := m.DB.AdminGetAllTradeLeads(ctx, database.AdminGetAllTradeLeadsParams{
		Column1: name,
		Limit:   filters.limitInt32(),
		Offset:  filters.offsetInt32(),
	})
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, Metadata{}, ErrGeneralRecordNotFound
		default:
			return nil, Metadata{}, err
		}
	}
	// check length of leads
	if len(leads) == 0 {
		return nil, Metadata{}, ErrGeneralRecordNotFound
	}
	// populate the leads slice
	leadRows := []*TradeLead{}
	totalRows := 0
	for _, leadRow := range leads {
		totalRows = int(leadRow.TotalCount)
		leadRows = append(leadRows, populateTradeLeads(leadRow))
	}
	// metadata
	metadata := calculateMetadata(totalRows, filters.Page, filters.PageSize)
	// return
	return leadRows, metadata, nil
}

// AdminUpdateTradeLeadStatus() updates the status of a trade lead in the database.
func (m TradeLeadModel) AdminUpdateTradeLeadStatus(leadID int64, version int32, lead *TradeLead) error {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// update the trade lead status in the database
	updatedLead, err := m.DB.AdminUpdateTradeLeadStatus(ctx, database.AdminUpdateTradeLeadStatusParams{
		ID:      leadID,
		Version: version,
	})
	if err != nil {
		switch {
		case strings.Contains(err.Error(), "trade_leads_status_check"):
			return ErrInvalidTradeLeadStatus
		default:
			return err
		}
	}
	// update lead
	lead.Version = updatedLead.Version
	lead.Status = updatedLead.Status
	lead.UpdatedAt = updatedLead.UpdatedAt
	return nil
}

// AdminGetTRadeLeadStats() retrieves statistics about trade leads from the database.
func (m TradeLeadModel) AdminGetTradeLeadStats() (*TradeStats, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultLeadManagerDBContextTimeout)
	defer cancel()
	// get trade lead stats
	stats, err := m.DB.AdminGetTRadeLeadStats(ctx)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrGeneralRecordNotFound
		default:
			return nil, err
		}
	}
	// Process the stats as needed
	tradeStats := &TradeStats{
		TotalLeads:         decimal.RequireFromString(stats.TotalLeads),
		TotalVerifiedValue: decimal.RequireFromString(stats.TotalVerifiedValue),
		VerifiedLeads:      decimal.RequireFromString(stats.VerifiedLeads),
	}
	return tradeStats, nil
}

func populateTradeLeads(tradeLeadRow any) *TradeLead {
	switch leadRow := tradeLeadRow.(type) {
	case database.TradeLead:
		return &TradeLead{
			ID:          leadRow.ID,
			TenantID:    leadRow.TenantID,
			Title:       leadRow.Title,
			Description: leadRow.Description.String,
			Status:      leadRow.Status,
			Value:       decimal.RequireFromString(leadRow.Value),
			Version:     leadRow.Version,
			CreatedAt:   leadRow.CreatedAt,
			UpdatedAt:   leadRow.UpdatedAt,
		}
	case database.GetAllLeadsByTenantIDRow:
		return &TradeLead{
			ID:          leadRow.ID,
			TenantID:    leadRow.TenantID,
			Title:       leadRow.Title,
			Description: leadRow.Description.String,
			Status:      leadRow.Status,
			Value:       decimal.RequireFromString(leadRow.Value),
			Version:     leadRow.Version,
			CreatedAt:   leadRow.CreatedAt,
			UpdatedAt:   leadRow.UpdatedAt,
		}
	case database.AdminGetAllTradeLeadsRow:
		return &TradeLead{
			ID:          leadRow.ID,
			TenantID:    leadRow.TenantID,
			Title:       leadRow.Title,
			Description: leadRow.Description.String,
			Status:      leadRow.Status,
			Value:       decimal.RequireFromString(leadRow.Value),
			Version:     leadRow.Version,
			CreatedAt:   leadRow.CreatedAt,
			UpdatedAt:   leadRow.UpdatedAt,
		}
	default:
		return nil // or handle the error as needed
	}
}
