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
