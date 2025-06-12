-- name: CreateTenant :one
INSERT INTO tenants (name, contact_email, description)
VALUES ($1, $2, $3)
RETURNING id, created_at, updated_at;

-- name: GetTenantByID :one
SELECT id, name, contact_email, description, created_at, updated_at
FROM tenants
WHERE id = $1;

-- name: AdminGetAllTenants :many
SELECT id, name, contact_email, description, created_at, updated_at
FROM tenants
WHERE ($1 = '' OR to_tsvector('simple', name) @@ plainto_tsquery('simple', $1))
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: UpdateTenant :one
UPDATE tenants
SET 
    name = $2,
    contact_email = $3,
    description = $4
WHERE id = $1
RETURNING id, name, contact_email, description, created_at, updated_at;