-- Routine Templates table
CREATE TABLE IF NOT EXISTS routine_templates (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(64) NOT NULL,
    time_window VARCHAR(32) NOT NULL,
    days_of_week JSONB NOT NULL DEFAULT '[]'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Daily Routine Items table
CREATE TABLE IF NOT EXISTS routine_items (
    id VARCHAR(64) PRIMARY KEY,
    template_id VARCHAR(64) REFERENCES routine_templates(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(64) NOT NULL,
    time_window VARCHAR(32) NOT NULL,
    scheduled_date DATE NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    completed_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_routine_items_date ON routine_items(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_routine_items_updated ON routine_items(updated_at);
CREATE INDEX IF NOT EXISTS idx_routine_items_status ON routine_items(status);
CREATE INDEX IF NOT EXISTS idx_routine_items_nfc ON routine_items USING gin (metadata);

-- Normalized Health Metrics table
CREATE TABLE IF NOT EXISTS health_metrics (
    id VARCHAR(64) PRIMARY KEY,
    source VARCHAR(64) NOT NULL,
    metric VARCHAR(64) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(32) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    external_id VARCHAR(255) UNIQUE,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_metrics_range ON health_metrics(metric, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_health_metrics_synced ON health_metrics(synced_at);
