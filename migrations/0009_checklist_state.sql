-- 0009_checklist_state.sql — сохранение отмеченных пунктов чеклистов (по ключу списка)
CREATE TABLE IF NOT EXISTS checklist_state (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    list_key   TEXT NOT NULL,                 -- напр. «Подготовка к роддому»
    items      TEXT[] NOT NULL DEFAULT '{}',  -- отмеченные пункты
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, list_key)
);
