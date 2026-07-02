import { Router } from 'express';
import { pool } from '../db.js';
import { hashPassword, verifyPassword, signToken } from '../services/auth.js';

export const authRouter = Router();

// Регистрация: создаёт пользователя и сразу выдаёт токен.
authRouter.post('/register', async (req, res) => {
  const { email, fullName, districtId, password, role } = req.body ?? {};
  if (!email || !password || !fullName || districtId == null) {
    return res.status(400).json({ error: 'missing_fields' });
  }
  try {
    const { rows } = await pool.query<{ id: string; role: string }>(
      `INSERT INTO users (email, full_name, district_id, role, password_hash)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, role`,
      [email, fullName, districtId, role ?? 'parent', hashPassword(password)]
    );
    const user = rows[0];
    return res.status(201).json({ token: signToken(user.id, user.role) });
  } catch (err) {
    if ((err as { code?: string }).code === '23505') {
      return res.status(409).json({ error: 'email_taken' });
    }
    console.error('[auth] register failed', err);
    return res.status(500).json({ error: 'internal' });
  }
});

// Логин: проверяет пароль, выдаёт токен.
authRouter.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  const { rows } = await pool.query<{
    id: string;
    role: string;
    password_hash: string | null;
  }>(`SELECT id, role, password_hash FROM users WHERE email = $1`, [email]);

  const user = rows[0];
  if (
    !user ||
    !user.password_hash ||
    !verifyPassword(password, user.password_hash)
  ) {
    return res.status(401).json({ error: 'invalid_credentials' });
  }
  return res.json({ token: signToken(user.id, user.role) });
});
