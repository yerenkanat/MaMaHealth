import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';

export const geoRouter = Router();

// Пациентка обновляет свою гео-позицию (экстренная геолокация).
geoRouter.post('/me/geo', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { lat, lng } = req.body ?? {};
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    return res.status(400).json({ error: 'bad_coords' });
  }

  const { rows } = await pool.query<{ district_id: number }>(
    'SELECT district_id FROM users WHERE id = $1',
    [userId]
  );
  const district = rows[0]?.district_id ?? 0;

  await pool.query(
    `INSERT INTO patient_locations (user_id, lat, lng, district_id, updated_at)
     VALUES ($1, $2, $3, $4, now())
     ON CONFLICT (user_id) DO UPDATE
       SET lat = EXCLUDED.lat, lng = EXCLUDED.lng,
           district_id = EXCLUDED.district_id, updated_at = now()`,
    [userId, lat, lng, district]
  );
  return res.status(204).end();
});
