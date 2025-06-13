package main

import (
	"errors"
	"net/http"

	"github.com/Blue-Davinci/leadhub-service/internal/data"
	"github.com/Blue-Davinci/leadhub-service/internal/validator"
	"github.com/shopspring/decimal"
	"go.uber.org/zap"
)

func (app *application) createTradeLeadHandler(w http.ResponseWriter, r *http.Request) {
	// input struct
	var input struct {
		Title       string          `json:"title"`
		Description string          `json:"description"`
		Value       decimal.Decimal `json:"value"`
	}
	// read the input from the request body
	if err := app.readJSON(w, r, &input); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// make a new TradeLead struct
	lead := &data.TradeLead{
		Title:       input.Title,
		Description: input.Description,
		Value:       input.Value,
	}
	// validate the input
	v := validator.New()
	if data.ValidateTradeLead(v, lead); !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// create the trade lead in the database
	// we use the user's tenant ID from the context to only create leads for the tenant they belong to
	if err := app.models.TradeLeads.CreateTradeLead(app.contextGetUser(r).TenantID, lead); err != nil {
		switch {
		case err == data.ErrInvalidTenantReference:
			app.notFoundResponse(w, r)
		case err == data.ErrInvalidTradeLeadStatus:
			app.badRequestResponse(w, r, err)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	err := app.writeJSON(w, http.StatusCreated, envelope{"trade_lead": lead}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// getAllLeadsByTenantIDHandler() is a method that will handle requests to get all trade leads for a specific tenant.
func (app *application) getAllLeadsByTenantIDHandler(w http.ResponseWriter, r *http.Request) {
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
	// Call the GetAllLeadsByTenantID method to retrieve the trade leads from the database.
	leads, metadata, err := app.models.TradeLeads.GetAllLeadsByTenantID(app.contextGetUser(r).TenantID, input.Name, input.Filters)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write the trade leads and metadata as a JSON response.
	err = app.writeJSON(w, http.StatusOK, envelope{"trade_leads": leads, "metadata": metadata}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// adminGetAllTradeLeadsHandler() is a method that will handle requests to retrieve all trade leads.
func (app *application) adminGetAllTradeLeadsHandler(w http.ResponseWriter, r *http.Request) {
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
	// Call the AdminGetAllTradeLeads method to retrieve the trade leads from the database.
	leads, metadata, err := app.models.TradeLeads.AdminGetAllTradeLeads(input.Name, input.Filters)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write the trade leads and metadata as a JSON response.
	err = app.writeJSON(w, http.StatusOK, envelope{"trade_leads": leads, "metadata": metadata}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// adminGetTradeLeadStatsHandler() is a method that will handle requests to retrieve trade lead statistics.
func (app *application) adminGetTradeLeadStatsHandler(w http.ResponseWriter, r *http.Request) {
	// Call the AdminGetTradeLeadStats method to retrieve the trade lead statistics from the database.
	stats, err := app.models.TradeLeads.AdminGetTradeLeadStats()
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write the trade lead statistics as a JSON response.
	err = app.writeJSON(w, http.StatusOK, envelope{"trade_lead_stats": stats}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}

// adminUpdateTradeLeadStatusHandler() is a method that will handle requests to update the status of a trade lead.
func (app *application) adminUpdateTradeLeadStatusHandler(w http.ResponseWriter, r *http.Request) {
	// get trade ID from the URL parameters
	leadID, err := app.readIDParam(r, "leadID")
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	// get version ID from the URL parameters
	versionID, err := app.readIDParam(r, "versionID")
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	app.logger.Info("Version and Lead ID", zap.Int64("leadID", leadID), zap.Int64("versionID", versionID))
	// check if the lead exists
	lead, err := app.models.TradeLeads.GetTradeLeadByID(leadID)
	if err != nil {
		switch {
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// let us update the lead status
	// Validate versionID can be safely converted to int32 (range: -2,147,483,648 to 2,147,483,647)
	if versionID > 2147483647 || versionID < -2147483648 {
		app.badRequestResponse(w, r, errors.New("version ID out of range"))
		return
	}
	err = app.models.TradeLeads.AdminUpdateTradeLeadStatus(leadID, int32(versionID), lead)
	if err != nil {
		switch {
		case err == data.ErrInvalidTradeLeadStatus:
			app.badRequestResponse(w, r, err)
		case err == data.ErrGeneralRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}
	// Write a JSON response with the updated trade lead details.
	err = app.writeJSON(w, http.StatusOK, envelope{"trade_lead": lead}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}

}
