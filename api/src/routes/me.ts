import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';

export const meRouter = Router();

// Профиль текущего пользователя + геймификация.
meRouter.get('/', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    full_name: string;
    city: string | null;
    points: number;
    streak: number;
    children: number;
  }>(
    `SELECT u.full_name, u.city, u.points, u.streak,
            (SELECT count(*) FROM children_profiles c
              WHERE c.user_id = u.id AND c.is_active) AS children
       FROM users u WHERE u.id = $1`,
    [userId]
  );
  const u = rows[0];
  if (!u) return res.status(404).json({ error: 'not_found' });
  return res.json({
    name: u.full_name,
    city: u.city,
    points: u.points,
    streak: u.streak,
    children: Number(u.children),
  });
});

// Ежедневный чек-ин: продлевает streak и начисляет баллы (идемпотентно за день).
meRouter.post('/checkin', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    streak: number;
    points: number;
    awarded: boolean;
  }>(
    `WITH prev AS (SELECT last_active_date AS d FROM users WHERE id = $1)
     UPDATE users u SET
        streak = CASE
          WHEN u.last_active_date = CURRENT_DATE THEN u.streak
          WHEN u.last_active_date = CURRENT_DATE - 1 THEN u.streak + 1
          ELSE 1
        END,
        points = u.points + CASE WHEN u.last_active_date IS DISTINCT FROM CURRENT_DATE THEN 10 ELSE 0 END,
        last_active_date = CURRENT_DATE
      WHERE u.id = $1
      RETURNING u.streak, u.points,
        ((SELECT d FROM prev) IS DISTINCT FROM CURRENT_DATE) AS awarded`,
    [userId]
  );
  return res.json(rows[0]);
});

// Персистентные замеры прибавки веса.
meRouter.get('/weight', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{ week: number; gain_kg: string }>(
    `SELECT week, gain_kg FROM weight_logs WHERE user_id = $1 ORDER BY week`,
    [userId]
  );
  return res.json(rows.map((r) => ({ week: r.week, gainKg: Number(r.gain_kg) })));
});

meRouter.post('/weight', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { week, gainKg } = req.body ?? {};
  if (typeof week !== 'number' || typeof gainKg !== 'number') {
    return res.status(400).json({ error: 'bad_input' });
  }
  await pool.query(
    `INSERT INTO weight_logs (user_id, week, gain_kg) VALUES ($1, $2, $3)
     ON CONFLICT (user_id, week) DO UPDATE SET gain_kg = EXCLUDED.gain_kg`,
    [userId, week, gainKg]
  );
  return res.status(204).end();
});

// История сессий подсчёта шевелений (последние 20).
meRouter.get('/kicks', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    id: string;
    count: number;
    duration_seconds: number;
    created_at: Date;
  }>(
    `SELECT id, count, duration_seconds, created_at
       FROM kick_sessions WHERE user_id = $1
      ORDER BY created_at DESC LIMIT 20`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({
      id: r.id,
      count: r.count,
      durationSeconds: r.duration_seconds,
      createdAt: r.created_at,
    }))
  );
});

// Сохранить завершённую сессию подсчёта шевелений.
meRouter.post('/kicks', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { count, durationSeconds } = req.body ?? {};
  if (
    typeof count !== 'number' ||
    count <= 0 ||
    typeof durationSeconds !== 'number' ||
    durationSeconds < 0
  ) {
    return res.status(400).json({ error: 'bad_input' });
  }
  const { rows } = await pool.query<{ id: string; created_at: Date }>(
    `INSERT INTO kick_sessions (user_id, count, duration_seconds)
     VALUES ($1, $2, $3) RETURNING id, created_at`,
    [userId, Math.round(count), Math.round(durationSeconds)]
  );
  return res.status(201).json({
    id: rows[0].id,
    count: Math.round(count),
    durationSeconds: Math.round(durationSeconds),
    createdAt: rows[0].created_at,
  });
});

// История схваток (последние 30, новые сверху).
meRouter.get('/contractions', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    id: string;
    duration_seconds: number;
    interval_seconds: number | null;
    created_at: Date;
  }>(
    `SELECT id, duration_seconds, interval_seconds, created_at
       FROM contraction_logs WHERE user_id = $1
      ORDER BY created_at DESC LIMIT 30`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({
      id: r.id,
      durationSeconds: r.duration_seconds,
      intervalSeconds: r.interval_seconds,
      createdAt: r.created_at,
    }))
  );
});

// Записать завершённую схватку.
meRouter.post('/contractions', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { durationSeconds, intervalSeconds } = req.body ?? {};
  if (typeof durationSeconds !== 'number' || durationSeconds < 0) {
    return res.status(400).json({ error: 'bad_input' });
  }
  const interval =
    typeof intervalSeconds === 'number' && intervalSeconds >= 0
      ? Math.round(intervalSeconds)
      : null;
  const { rows } = await pool.query<{ id: string; created_at: Date }>(
    `INSERT INTO contraction_logs (user_id, duration_seconds, interval_seconds)
     VALUES ($1, $2, $3) RETURNING id, created_at`,
    [userId, Math.round(durationSeconds), interval]
  );
  return res.status(201).json({
    id: rows[0].id,
    durationSeconds: Math.round(durationSeconds),
    intervalSeconds: interval,
    createdAt: rows[0].created_at,
  });
});
