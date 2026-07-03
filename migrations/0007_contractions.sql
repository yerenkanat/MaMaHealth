-- 0007_contractions.sql — журнал схваток (длительность + интервал от предыдущей)
CREATE TABLE IF NOT EXISTS contraction_logs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duration_seconds INT NOT NULL CHECK (duration_seconds >= 0),
    interval_seconds INT CHECK (interval_seconds >= 0),  -- NULL для первой схватки
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_contraction_logs_user_created
    ON contraction_logs (user_id, created_at DESC);
