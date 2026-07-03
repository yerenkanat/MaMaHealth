-- 0006_kick_sessions.sql — сессии подсчёта шевелений плода (count-to-ten и т.п.)
CREATE TABLE IF NOT EXISTS kick_sessions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    count            INT NOT NULL CHECK (count > 0),
    duration_seconds INT NOT NULL CHECK (duration_seconds >= 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_kick_sessions_user_created
    ON kick_sessions (user_id, created_at DESC);
