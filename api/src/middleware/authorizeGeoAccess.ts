import { Request, Response, NextFunction } from 'express';
import { pool } from '../db.js';

/**
 * BOLA/IDOR guard: доступ врача к гео-позиции пациентки.
 * Проверяем ЯВНУЮ активную связь doctor↔patient + совпадение района,
 * а не только «врач ли ты вообще». patient_id берём из params, doctor_id — из JWT.
 */
export async function authorizeGeoAccess(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const doctorId = req.auth?.userId;
  const patientId = req.params.patientId;

  if (!doctorId || req.auth?.role !== 'doctor') {
    return res.status(403).json({ error: 'forbidden' });
  }

  const { rows } = await pool.query<{ ok: boolean }>(
    `SELECT EXISTS (
       SELECT 1
         FROM doctor_patient_links l
         JOIN users d ON d.id = l.doctor_id
         JOIN users p ON p.id = l.patient_id
        WHERE l.doctor_id = $1
          AND l.patient_id = $2
          AND l.status = 'active'
          AND d.district_id = p.district_id
     ) AS ok`,
    [doctorId, patientId]
  );

  if (!rows[0]?.ok) {
    // Потенциальный IDOR-скан — логируем как security-инцидент.
    console.warn(`[SECURITY] Denied geo access: doctor=${doctorId} -> patient=${patientId}`);
    // 404, а не 403 — не раскрываем существование объекта.
    return res.status(404).json({ error: 'not_found' });
  }

  next();
}
