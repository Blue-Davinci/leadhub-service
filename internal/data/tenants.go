package data

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/Blue-Davinci/leadhub-service/internal/database"
)

type TenantsModel struct {
	DB *database.Queries
}

const (
	DefaultTenantManagerDBContextTimeout = 5 * time.Second
)

type Tenant struct {
	ID           int64     `json:"id"`
	Name         string    `json:"name"`
	ContactEmail string    `json:"contact_email"`
	Description  string    `json:"description"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

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

func populateTenants(tenantRow any) *Tenant {
	switch tenantRow := tenantRow.(type) {
	case database.GetTenantByIDRow:
		return &Tenant{
			ID:           tenantRow.ID,
			Name:         tenantRow.Name,
			ContactEmail: tenantRow.ContactEmail,
			Description:  tenantRow.Description.String,
			CreatedAt:    tenantRow.CreatedAt,
			UpdatedAt:    tenantRow.UpdatedAt,
		}
	default:
		// return nil
		return nil
	}
}
