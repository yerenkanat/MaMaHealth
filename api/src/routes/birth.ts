import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';
import { scheduleChildAlerts } from '../services/childScheduler.js';

export const birthRouter = Router();

/**
 * Триггер «Я родила!». Атомарная миграция беременность -> ребёнок.
 * Идемпотентность через idempotency_key: повторный вызов не создаёт второго ребёнка.
 */
birthRouter.post('/:pregnancyId/birth', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { pregnancyId } = req.params;
  const { name, gender, birthDate, birthWeightG, birthHeightCm } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Проверяем, что беременность принадлежит пользователю и ещё активна.
    const preg = await client.query<{ status: string; child_id: string | null }>(
      `SELECT status, child_id FROM pregnancies
        WHERE id = $1 AND user_id = $2 FOR UPDATE`,
      [pregnancyId, userId]
    );
    if (preg.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'not_found' });
    }
    // Идемпотентность: уже мигрировали — возвращаем существующего ребёнка.
    if (preg.rows[0].child_id) {
      await client.query('COMMIT');
      return res.status(200).json({ childId: preg.rows[0].child_id, alreadyDone: true });
    }

    // 2. Создаём профиль ребёнка.
    const child = await client.query<{ id: string }>(
      `INSERT INTO children_profiles
         (user_id, name, gender, birth_date, birth_weight_g, birth_height_cm)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [userId, name, gender, birthDate, birthWeightG, birthHeightCm]
    );
    const childId = child.rows[0].id;

    // 3. Архивируем беременность и связываем с ребёнком.
    await client.query(
      `UPDATE pregnancies
          SET status='completed', outcome='birth', child_id=$1
        WHERE id=$2`,
      [childId, pregnancyId]
    );

    // 4. Отменяем будущие пуши беременности.
    await client.query(
      `UPDATE scheduled_alerts SET status='cancelled'
        WHERE profile_type='PREGNANCY' AND profile_id=$1 AND status='pending'`,
      [pregnancyId]
    );

    // 5. Сразу генерируем расписание новорождённого (возраст 0 → БЦЖ + гепатит B).
    //    Идемпотентно: повторный вызов не создаст дублей.
    await scheduleChildAlerts(client, childId, new Date(birthDate), new Date());

    await client.query('COMMIT');
    return res.status(201).json({ childId, alreadyDone: false });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[birth] migration failed', err);
    return res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});
