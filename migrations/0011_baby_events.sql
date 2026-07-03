-- 0011_baby_events.sql — дневник малыша: кормления, сон, подгузники
CREATE TABLE IF NOT EXISTS baby_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        TEXT NOT NULL CHECK (type IN ('feed', 'sleep', 'diaper')),
    detail      TEXT,                       -- напр. breast/bottle, wet/dirty, длительность сна
    happened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_baby_events_user_time
    ON baby_events (user_id, happened_at DESC);
