package main

import (
	"errors"
	"net/http"

	"github.com/Blue-Davinci/leadhub-service/internal/data"
	"github.com/Blue-Davinci/leadhub-service/internal/validator"
)

// The getTenantByIDHandler() method will handle requests to retrieve a tenant by its ID.
// This is user specific, so we will extract their user information from the request context
// and use it to fetch the tenant details from the database.
// It will return a JSON response with the tenant details or an error if the tenant is not found.
func (app *application) getTenantByIDHandler(w http.ResponseWriter, r *http.Request) {
	// Extract the user from the request context.
	user := app.contextGetUser(r)

	// Fetch the tenant details from the database using the user ID and tenant ID.
	tenant, err := app.models.Tenants.GetTenantByID(user.ID)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write the tenant details as a JSON response.
	err = app.writeJSON(w, http.StatusOK, envelope{"tenant": tenant}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// adminGetAllTenantsHandler() is a method that will handle requests to retrieve all tenants.
// It supports pagination and name aearching.
func (app *application) adminGetAllTenantsHandler(w http.ResponseWriter, r *http.Request) {
	// make a struct to hold what we would want from the queries
	var input struct {
		Name string
		data.Filters
	}
	v := validator.New()
	// Call r.URL.Query() to get the url.Values map containing the query string data.
	qs := r.URL.Query()
	// get our parameters
	input.Name = app.readString(qs, "name", "")
	//get the page & pagesizes as ints and set to the embedded struct
	input.Filters.Page = app.readInt(qs, "page", 1, v)
	input.Filters.PageSize = app.readInt(qs, "page_size", 20, v)
	// We don't use any sort for this endpoint
	input.Filters.Sort = app.readString(qs, "", "")
	// None of the sort values are supported for this endpoint
	input.Filters.SortSafelist = []string{"", ""}
	// Perform validation
	if data.ValidateFilters(v, input.Filters); !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// Call the AdminGetAllTenants method to retrieve the tenants from the database.
	tenants, metadata, err := app.models.Tenants.AdminGetAllTenants(input.Name, input.Filters)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write the tenants and metadata as a JSON response.
	err = app.writeJSON(w, http.StatusOK, envelope{"tenants": tenants, "metadata": metadata}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// The CreateTenant() is an ADMIN method that will handle requests to create a new tenant.
// It will extract the tenant details from the request body, validate them,
// and then create the tenant in the database.
func (app *application) createTenantHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Name         string `json:"name"`
		ContactEmail string `json:"contact_email"`
		Description  string `json:"description"`
	}
	if err := app.readJSON(w, r, &input); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// create a new tenant struct
	tenant := &data.Tenant{
		Name:         input.Name,
		ContactEmail: input.ContactEmail,
		Description:  input.Description,
	}

	// Initialize a new Validator.
	v := validator.New()
	if data.ValidateTenant(v, tenant); !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// Create the tenant in the database.
	if err := app.models.Tenants.CreateTenant(tenant); err != nil {
		switch {
		case err == data.ErrTenantAlreadyExists:
			v.AddError("name", "tenant with this name already exists")
			app.failedValidationResponse(w, r, v.Errors)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write a JSON response with the created tenant details.
	err := app.writeJSON(w, http.StatusCreated, envelope{"tenant": tenant}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// updateTenantHandler() is a method that will handle requests to update an existing tenant.
func (app *application) updateTenantHandler(w http.ResponseWriter, r *http.Request) {
	// read tenant id from URL parameters
	tenantID, err := app.readIDParam(r, "tenantID")
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// read versionID from URL parameters
	versionID, err := app.readIDParam(r, "versionID")
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// validate
	v := validator.New()
	// validate the tenant ID
	if data.ValidateURLID(v, tenantID, "id"); !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// make an input struct to hold the tenant details
	var input struct {
		Name         *string `json:"name"`
		ContactEmail *string `json:"contact_email"`
		Description  *string `json:"description"`
	}
	if err := app.readJSON(w, r, &input); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// get the tenant by ID
	tenant, err := app.models.Tenants.GetTenantByID(tenantID)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// check which fields are being updated
	if input.Name != nil {
		tenant.Name = *input.Name
	}
	if input.ContactEmail != nil {
		tenant.ContactEmail = *input.ContactEmail
	}
	if input.Description != nil {
		tenant.Description = *input.Description
	}
	// Validate the updated tenant details.
	if data.ValidateTenant(v, tenant); !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// Update the tenant in the database.
	// Validate versionID can be safely converted to int32
	if versionID > 2147483647 || versionID < -2147483648 {
		app.badRequestResponse(w, r, errors.New("version ID out of range"))
		return
	}
	if err := app.models.Tenants.UpdateTenant(tenant, int32(versionID)); err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		case err == data.ErrTenantAlreadyExists:
			v.AddError("name", "tenant with this name already exists")
			app.failedValidationResponse(w, r, v.Errors)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write a JSON response with the updated tenant details.
	err = app.writeJSON(w, http.StatusOK, envelope{"tenant": tenant}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}
