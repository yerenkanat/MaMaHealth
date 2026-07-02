-- 0003_auth.sql — учётные данные пользователей
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
