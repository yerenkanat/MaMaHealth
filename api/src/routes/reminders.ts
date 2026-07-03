import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';

export const remindersRouter = Router();

// Инбокс медицинских напоминаний пользователя (из scheduled_alerts).
remindersRouter.get('/', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    id: string;
    title: string;
    category: string;
    is_critical: boolean;
    fire_date: string;
    profile_type: string;
  }>(
    `SELECT sa.id, mp.title, mp.category, mp.is_critical, sa.fire_date, sa.profile_type
       FROM scheduled_alerts sa
       JOIN medical_protocols mp ON mp.id = sa.protocol_id
       LEFT JOIN children_profiles ch
         ON sa.profile_type = 'CHILD' AND ch.id = sa.profile_id AND ch.user_id = $1
       LEFT JOIN pregnancies pg
         ON sa.profile_type = 'PREGNANCY' AND pg.id = sa.profile_id AND pg.user_id = $1
      WHERE sa.status = 'pending' AND (ch.id IS NOT NULL OR pg.id IS NOT NULL)
      ORDER BY sa.fire_date`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({
      id: r.id,
      title: r.title,
      category: r.category,
      isCritical: r.is_critical,
      fireDate: r.fire_date,
      profileType: r.profile_type,
    }))
  );
});
