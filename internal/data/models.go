package data

import (
	"errors"

	"github.com/Blue-Davinci/leadhub-service/internal/database"
)

var (
	ErrGeneralRecordNotFound = errors.New("finance record not found")
	ErrGeneralEditConflict   = errors.New("edit conflict")
)

type Models struct {
	Tenants TenantsModel
	Users   UserModel
	Tokens  TokenModel
}

func NewModels(db *database.Queries) Models {
	return Models{
		Tenants: TenantsModel{DB: db},
		Users:   UserModel{DB: db},
		Tokens:  TokenModel{DB: db},
	}
}
