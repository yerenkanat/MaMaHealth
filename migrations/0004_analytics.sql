-- 0004_analytics.sql — медальонная аналитика Bronze -> Silver -> Gold
CREATE SCHEMA IF NOT EXISTS analytics;

-- === BRONZE: сырые события приложения (как есть) ===
CREATE TABLE IF NOT EXISTS analytics.bronze_events (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID,
    event_type  TEXT NOT NULL,          -- app_open, screening_done, kick_logged, ...
    payload     JSONB NOT NULL DEFAULT '{}',
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bronze_events_type_time
    ON analytics.bronze_events (event_type, occurred_at);

-- === SILVER: очищенные, типизированные факты ===
-- Уведомления, обогащённые районом пациентки/ребёнка.
CREATE OR REPLACE VIEW analytics.silver_alerts AS
SELECT
    sa.id,
    sa.profile_type,
    sa.profile_id,
    sa.status,
    sa.fire_date,
    mp.scope,
    mp.category,
    mp.title,
    mp.week_number,
    mp.child_age_in_months,
    COALESCE(cu.district_id, pu.district_id) AS district_id
FROM scheduled_alerts sa
JOIN medical_protocols mp ON mp.id = sa.protocol_id
LEFT JOIN children_profiles ch ON sa.profile_type = 'CHILD' AND ch.id = sa.profile_id
LEFT JOIN users cu ON cu.id = ch.user_id
LEFT JOIN pregnancies pg ON sa.profile_type = 'PREGNANCY' AND pg.id = sa.profile_id
LEFT JOIN users pu ON pu.id = pg.user_id;

-- Ежедневная активность (из bronze).
CREATE OR REPLACE VIEW analytics.silver_daily_activity AS
SELECT
    user_id,
    date_trunc('day', occurred_at)::date AS day,
    count(*) AS events
FROM analytics.bronze_events
WHERE user_id IS NOT NULL
GROUP BY user_id, date_trunc('day', occurred_at)::date;

-- === GOLD: витрины для клиник/админки ===
-- % выполнения скринингов/прививок по районам и категориям.
CREATE OR REPLACE VIEW analytics.gold_screening_completion AS
SELECT
    district_id,
    category,
    count(*)                                   AS total,
    count(*) FILTER (WHERE status = 'sent')    AS completed,
    round(100.0 * count(*) FILTER (WHERE status = 'sent')
          / NULLIF(count(*), 0), 1)            AS completion_pct
FROM analytics.silver_alerts
GROUP BY district_id, category
ORDER BY district_id, category;

-- Скрининг на 12-й неделе в разрезе районов (пример из ТЗ).
CREATE OR REPLACE VIEW analytics.gold_week12_screening AS
SELECT
    district_id,
    count(*)                                   AS scheduled,
    count(*) FILTER (WHERE status = 'sent')    AS done,
    round(100.0 * count(*) FILTER (WHERE status = 'sent')
          / NULLIF(count(*), 0), 1)            AS pct
FROM analytics.silver_alerts
WHERE scope = 'PREGNANCY' AND week_number = 12
GROUP BY district_id
ORDER BY district_id;

-- Вовлечённость: MAU-подобная метрика активных пользователей по дням.
CREATE OR REPLACE VIEW analytics.gold_daily_active_users AS
SELECT day, count(DISTINCT user_id) AS active_users
FROM analytics.silver_daily_activity
GROUP BY day
ORDER BY day;
