-- 0013_water_logs.sql — дневной трекер воды (стаканы), одна запись на день
CREATE TABLE IF NOT EXISTS water_logs (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date   DATE NOT NULL,
    glasses    INT NOT NULL DEFAULT 0 CHECK (glasses >= 0 AND glasses <= 30),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, log_date)
);
