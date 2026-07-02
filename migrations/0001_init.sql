-- 0001_init.sql — базовая схема MaMa
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

-- === Пользователи ===
CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email        CITEXT UNIQUE NOT NULL,
    full_name    TEXT NOT NULL,
    role         TEXT NOT NULL DEFAULT 'parent' CHECK (role IN ('parent','doctor','admin')),
    district_id  INT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- === Дети ===
CREATE TABLE children_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    gender          TEXT NOT NULL CHECK (gender IN ('male','female')),
    birth_date      TIMESTAMPTZ NOT NULL,
    birth_weight_g  INT CHECK (birth_weight_g BETWEEN 500 AND 6000),
    birth_height_cm NUMERIC(4,1),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- === Беременности ===
CREATE TABLE pregnancies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    due_date     DATE NOT NULL,
    lmp_date     DATE,
    status       TEXT NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','completed','archived')),
    outcome      TEXT CHECK (outcome IN ('birth','loss')),
    child_id     UUID REFERENCES children_profiles(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- === Справочник медицинских протоколов (ВОЗ / Минздрав) ===
CREATE TABLE medical_protocols (
    id                  SERIAL PRIMARY KEY,
    scope               TEXT NOT NULL CHECK (scope IN ('PREGNANCY','CHILD')),
    week_number         INT,
    child_age_in_months INT,
    category            TEXT NOT NULL CHECK (category IN ('screening','vaccination','checkup')),
    title               TEXT NOT NULL,
    description         TEXT NOT NULL,
    is_critical         BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT scope_axis CHECK (
        (scope='PREGNANCY' AND week_number IS NOT NULL AND child_age_in_months IS NULL) OR
        (scope='CHILD'     AND child_age_in_months IS NOT NULL AND week_number IS NULL)
    )
);

-- === Очередь запланированных уведомлений ===
CREATE TABLE scheduled_alerts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_type TEXT NOT NULL CHECK (profile_type IN ('PREGNANCY','CHILD')),
    profile_id   UUID NOT NULL,
    protocol_id  INT NOT NULL REFERENCES medical_protocols(id),
    fire_date    DATE NOT NULL,
    status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','sent','cancelled')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- 🔑 идемпотентность воркера
    UNIQUE (profile_id, protocol_id, fire_date)
);

-- === Партиальные индексы (горячие пути) ===
CREATE INDEX idx_pregnancies_active   ON pregnancies (due_date)        WHERE status = 'active';
CREATE INDEX idx_children_active      ON children_profiles (birth_date) WHERE is_active = TRUE;
CREATE INDEX idx_protocols_child_month ON medical_protocols (child_age_in_months) WHERE scope = 'CHILD';
CREATE INDEX idx_protocols_preg_week   ON medical_protocols (week_number)         WHERE scope = 'PREGNANCY';
CREATE INDEX idx_alerts_pending        ON scheduled_alerts (fire_date)            WHERE status = 'pending';
