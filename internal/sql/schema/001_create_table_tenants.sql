-- +goose Up
CREATE TABLE
    tenants (
        id BIGSERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        contact_email TEXT NOT NULL,
        description TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );

CREATE INDEX idx_tenants_name ON tenants (name);
CREATE INDEX idx_tenants_contact_email ON tenants (contact_email);

-- +goose StatementBegin
-- Function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    -- Ensure the version is incremented on update
    IF TG_OP = 'UPDATE' THEN
        NEW.version = NEW.version + 1;
    END IF;
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

-- Trigger to automatically update updated_at on row updates
CREATE TRIGGER update_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- +goose Down
DROP TRIGGER IF EXISTS update_tenants_updated_at ON tenants;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP INDEX IF EXISTS idx_tenants_contact_email;
DROP INDEX IF EXISTS idx_tenants_name;
DROP TABLE IF EXISTS tenants;