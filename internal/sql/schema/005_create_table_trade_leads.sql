-- +goose Up
CREATE TABLE trade_leads (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL CHECK (status IN ('new', 'verified', 'closed')) DEFAULT 'new',
    value NUMERIC(18, 2) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- +goose StatementBegin
-- Function to automatically update updated_at inherited from tenants
CREATE TRIGGER update_trade_lead_updated_at
BEFORE UPDATE ON trade_leads
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
-- +goose StatementEnd

CREATE INDEX idx_trade_leads_tenant_id ON trade_leads(tenant_id);
CREATE INDEX idx_trade_leads_status ON trade_leads(status);

-- +goose Down
DROP INDEX IF EXISTS idx_trade_leads_status;
DROP INDEX IF EXISTS idx_trade_leads_tenant_id;
DROP TABLE IF EXISTS trade_leads;
