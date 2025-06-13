package data

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/Blue-Davinci/leadhub-service/internal/database"
	"github.com/Blue-Davinci/leadhub-service/internal/validator"
)

type TenantsModel struct {
	DB *database.Queries
}

var (
	ErrTenantAlreadyExists = errors.New("tenant already exists")
)

const (
	DefaultTenantManagerDBContextTimeout = 5 * time.Second
)

type Tenant struct {
	ID           int64     `json:"id"`
	Name         string    `json:"name"`
	ContactEmail string    `json:"contact_email"`
	Description  string    `json:"description"`
	Version      int32     `json:"version"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func ValidateTenant(v *validator.Validator, tenant *Tenant) {
	// Check if the tenant name is provided and valid
	v.Check(tenant.Name != "", "name", "must be provided")

	// Check if the contact email is provided and valid
	ValidateEmail(v, tenant.ContactEmail)

	// Check if the description is not too long
	v.Check(len(tenant.Description) <= 500, "description", "must not be more than 500 characters long")
}

// GetTenantByID() retrieves a tenant by its ID from the database.
func (m TenantsModel) GetTenantByID(id int64) (*Tenant, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultTenantManagerDBContextTimeout)
	defer cancel()
	// get tenant by ID
	tenant, err := m.DB.GetTenantByID(ctx, id)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrGeneralRecordNotFound
		default:
			return nil, err
		}
	}
	// populate the tenant struct
	return populateTenants(tenant), nil
}

// AdminGetAllTenants() retrieves all tenants from the database.
func (m TenantsModel) AdminGetAllTenants(tenantName string, filters Filters) ([]*Tenant, Metadata, error) {
	ctx, cancel := contextGenerator(context.Background(), DefaultTenantManagerDBContextTimeout)
	defer cancel()
	// get all tenants
	tenants, err := m.DB.AdminGetAllTenants(ctx, database.AdminGetAllTenantsParams{
		Column1: tenantName,
		Limit:   int32(filters.limit()),
		Offset:  int32(filters.offset()),
	})
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, Metadata{}, ErrGeneralRecordNotFound
		default:
			return nil, Metadata{}, err
		}
	}
	// check length of tenants
	if len(tenants) == 0 {
		return nil, Metadata{}, ErrGeneralRecordNotFound
	}
	// populate the tenants slice
	tenantRows := []*Tenant{}
	totalRows := 0
	for _, tenantRow := range tenants {
		totalRows = int(tenantRow.TotalCount)
		tenantRows = append(tenantRows, populateTenants(tenantRow))
	}
	// metadata
	metadata := calculateMetadata(totalRows, filters.Page, filters.PageSize)
	// return
	return tenantRows, metadata, nil
}

// CreateTenant() creates a new tenant in the database.
func (m TenantsModel) CreateTenant(tenant *Tenant) error {
	ctx, cancel := contextGenerator(context.Background(), DefaultTenantManagerDBContextTimeout)
	defer cancel()

	// Create the tenant in the database
	newTenant, err := m.DB.CreateTenant(ctx, database.CreateTenantParams{
		Name:         tenant.Name,
		ContactEmail: tenant.ContactEmail,
		Description:  sql.NullString{String: tenant.Description, Valid: true},
	})
	if err != nil {
		switch {
		case strings.Contains(err.Error(), "tenants_name_key"):
			return ErrTenantAlreadyExists
		default:
			return err
		}
	}
	// Populate the tenant struct with the new tenant data
	tenant.ID = newTenant.ID
	tenant.CreatedAt = newTenant.CreatedAt
	tenant.UpdatedAt = newTenant.UpdatedAt
	// we are good to go
	return nil
}

// UpdateTenant() updates an existing tenant in the database.
func (m TenantsModel) UpdateTenant(tenant *Tenant, versionID int32) error {
	ctx, cancel := contextGenerator(context.Background(), DefaultTenantManagerDBContextTimeout)
	defer cancel()

	// Update the tenant in the database
	updatedTenant, err := m.DB.UpdateTenant(ctx, database.UpdateTenantParams{
		ID:           tenant.ID,
		Name:         tenant.Name,
		ContactEmail: tenant.ContactEmail,
		Description:  sql.NullString{String: tenant.Description, Valid: true},
		Version:      versionID,
	})
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return ErrGeneralEditConflict
		case strings.Contains(err.Error(), "tenants_name_key"):
			return ErrTenantAlreadyExists
		default:
			return err
		}
	}
	// update the tenant struct with the updated data
	tenant.UpdatedAt = updatedTenant.UpdatedAt
	tenant.Version = updatedTenant.Version
	// we are good to go
	return nil
}

func populateTenants(tenantRow any) *Tenant {
	switch tenantRow := tenantRow.(type) {
	case database.Tenant:
		return &Tenant{
			ID:           tenantRow.ID,
			Name:         tenantRow.Name,
			ContactEmail: tenantRow.ContactEmail,
			Description:  tenantRow.Description.String,
			Version:      tenantRow.Version,
			CreatedAt:    tenantRow.CreatedAt,
			UpdatedAt:    tenantRow.UpdatedAt,
		}
	case database.AdminGetAllTenantsRow:
		return &Tenant{
			ID:           tenantRow.ID,
			Name:         tenantRow.Name,
			ContactEmail: tenantRow.ContactEmail,
			Description:  tenantRow.Description.String,
			Version:      tenantRow.Version,
			CreatedAt:    tenantRow.CreatedAt,
			UpdatedAt:    tenantRow.UpdatedAt,
		}
	default:
		// return nil
		return nil
	}
}
