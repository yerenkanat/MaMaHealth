-- 0008_daily_log.sql — ежедневный лог самочувствия и настроения (Flo-style), 1 запись/день
CREATE TABLE IF NOT EXISTS daily_logs (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date   DATE NOT NULL,
    mood       TEXT,              -- great | good | ok | low | bad
    symptoms   TEXT[] NOT NULL DEFAULT '{}',
    note       TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_logs_user_date
    ON daily_logs (user_id, log_date DESC);
