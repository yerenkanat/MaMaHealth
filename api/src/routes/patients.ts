import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';
import { authorizeGeoAccess } from '../middleware/authorizeGeoAccess.js';

export const patientsRouter = Router();

// Гео-позиция пациентки — только для связанного врача того же района.
patientsRouter.get(
  '/:patientId/geo',
  verifyJwt,
  authorizeGeoAccess,
  async (req, res) => {
    const { rows } = await pool.query<{
      lat: number;
      lng: number;
      updated_at: Date;
    }>(
      `SELECT lat, lng, updated_at
         FROM patient_locations
        WHERE user_id = $1`,
      [req.params.patientId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'no_location' });
    }
    return res.json(rows[0]);
  }
);
