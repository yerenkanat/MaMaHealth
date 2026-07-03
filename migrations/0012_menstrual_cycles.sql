-- 0012_menstrual_cycles.sql — трекинг менструального цикла (Flo-style)
CREATE TABLE IF NOT EXISTS menstrual_cycles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date   DATE,                    -- NULL, пока месячные идут
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, start_date)
);

CREATE INDEX IF NOT EXISTS idx_menstrual_cycles_user_start
    ON menstrual_cycles (user_id, start_date DESC);
