-- +goose Up
CREATE TABLE trade_leads (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL CHECK (status IN ('new', 'verified', 'closed')) DEFAULT 'new',
    value NUMERIC(18, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_trade_leads_tenant_id ON trade_leads(tenant_id);
CREATE INDEX idx_trade_leads_status ON trade_leads(status);

-- +goose Down
DROP INDEX IF EXISTS idx_trade_leads_status;
DROP INDEX IF EXISTS idx_trade_leads_tenant_id;
DROP TABLE IF EXISTS trade_leads;
