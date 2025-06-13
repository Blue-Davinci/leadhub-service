-- name: GetAllLeadsByTenantID :many
SELECT 
  COUNT(*) OVER() AS total_count,
  id, 
  tenant_id, 
  title, 
  description, 
  status, 
  value, 
  version,
  created_at, 
  updated_at
FROM trade_leads
WHERE tenant_id = $1
  AND ($2 = '' OR to_tsvector('simple', title) @@ plainto_tsquery('simple', $2))
ORDER BY created_at DESC
LIMIT $3 OFFSET $4;

-- name: GetTradeLeadByID :one
SELECT 
  id, 
  tenant_id, 
  title, 
  description, 
  status, 
  value, 
  version,
  created_at, 
  updated_at
FROM trade_leads
WHERE id = $1;

-- name: AdminGetAllTradeLeads :many
SELECT 
  COUNT(*) OVER() AS total_count,
  id, 
  tenant_id, 
  title, 
  description, 
  status, 
  value, 
  version,
  created_at, 
  updated_at
FROM trade_leads
WHERE ($1 = '' OR to_tsvector('simple', title) @@ plainto_tsquery('simple', $1))
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;


-- name: CreateTradeLead :one
INSERT INTO trade_leads (
  tenant_id,
  title,
  description,
  value
) VALUES (
  $1, $2, $3, $4
)
RETURNING id,tenant_id, version, created_at, updated_at;

-- name: AdminUpdateTradeLeadStatus :one
UPDATE trade_leads
SET 
  status = 'verified'
WHERE id = $1 AND version = $2 AND status = 'new'
RETURNING version, status, updated_at;


-- name: AdminGetTRadeLeadStats :one
SELECT 
  COUNT(*)::text AS total_leads,
  COUNT(*) FILTER (WHERE status = 'verified')::text AS verified_leads,
  COALESCE(SUM(value) FILTER (WHERE status = 'verified'), 0)::text AS total_verified_value
FROM trade_leads;
