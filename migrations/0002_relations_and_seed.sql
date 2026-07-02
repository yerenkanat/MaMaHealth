-- 0002_relations_and_seed.sql — связи врач↔пациент + seed медпротоколов

-- === Связи врач ↔ пациент (основа BOLA/IDOR-guard) ===
CREATE TABLE doctor_patient_links (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status     TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (doctor_id, patient_id)
);

CREATE INDEX idx_dpl_active ON doctor_patient_links (doctor_id, patient_id)
    WHERE status = 'active';

-- === Последняя известная гео-позиция пациентки (экстренная) ===
CREATE TABLE patient_locations (
    user_id     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    district_id INT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- === Seed: медицинские протоколы ===
-- Беременность (по неделям)
INSERT INTO medical_protocols (scope, week_number, category, title, description, is_critical) VALUES
  ('PREGNANCY', 12, 'screening', 'Первый скрининг',        'УЗИ + биохимия (PAPP-A, β-ХГЧ). Оценка риска хромосомных аномалий.', TRUE),
  ('PREGNANCY', 20, 'screening', 'Второй скрининг',        'Анатомическое УЗИ плода.',                                          TRUE),
  ('PREGNANCY', 28, 'checkup',   'Тест на глюкозу',        'Глюкозотолерантный тест (ГТТ) для скрининга гестационного диабета.', FALSE),
  ('PREGNANCY', 36, 'checkup',   'Подготовка к родам',     'Оценка положения плода, план родов, тревожная сумка.',              FALSE);

-- Ребёнок (по месяцам) — упрощённый нац. календарь вакцинации
INSERT INTO medical_protocols (scope, child_age_in_months, category, title, description, is_critical) VALUES
  ('CHILD', 0,  'vaccination', 'БЦЖ + гепатит B',           'Первые прививки в роддоме.',                          TRUE),
  ('CHILD', 2,  'vaccination', 'Пневмококк + пентаксим',    'АКДС, полиомиелит, ХИБ, пневмококковая инфекция.',    TRUE),
  ('CHILD', 4,  'vaccination', 'Вторая доза пентаксим',     'Ревакцинация комплекса.',                             TRUE),
  ('CHILD', 6,  'checkup',     'Осмотр в 6 месяцев',        'Оценка моторных навыков и введение прикорма.',        FALSE),
  ('CHILD', 12, 'vaccination', 'Корь, краснуха, паротит',   'КПК — первая доза.',                                  TRUE);
