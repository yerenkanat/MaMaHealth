import { Router } from 'express';
import { pool } from '../db.js';
import { verifyJwt } from '../middleware/verifyJwt.js';
import { ageInMonths } from '../services/childScheduler.js';

export const profilesRouter = Router();

const PREGNANCY_TOTAL_WEEKS = 42;
const CHILD_TOTAL_MONTHS = 24;
const DAY_MS = 86_400_000;

/** 0-based индекс текущей недели беременности для таймлайна. */
function pregnancyWeekIndex(
  dueDate: Date,
  lmpDate: Date | null,
  now: Date
): number {
  let week: number;
  if (lmpDate) {
    week = Math.floor((now.getTime() - lmpDate.getTime()) / (7 * DAY_MS)) + 1;
  } else {
    // ПДР = 40 недель гестации: прошло = 40 − недель до ПДР.
    const weeksToDue = Math.ceil((dueDate.getTime() - now.getTime()) / (7 * DAY_MS));
    week = 40 - weeksToDue;
  }
  const idx = week - 1;
  return Math.min(Math.max(idx, 0), PREGNANCY_TOTAL_WEEKS - 1);
}

/**
 * Список активных профилей пользователя (одна беременность + N детей)
 * в форме, ожидаемой Flutter-клиентом (Profile.fromJson).
 */
profilesRouter.get('/', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const now = new Date();

  const pregnancies = await pool.query<{
    id: string;
    due_date: Date;
    lmp_date: Date | null;
  }>(
    `SELECT id, due_date, lmp_date FROM pregnancies
      WHERE user_id = $1 AND status = 'active'`,
    [userId]
  );

  const children = await pool.query<{
    id: string;
    name: string;
    birth_date: Date;
  }>(
    `SELECT id, name, birth_date FROM children_profiles
      WHERE user_id = $1 AND is_active = TRUE
      ORDER BY birth_date DESC`,
    [userId]
  );

  const profiles = [
    ...pregnancies.rows.map((p) => ({
      id: p.id,
      type: 'PREGNANCY' as const,
      title: 'Беременность',
      currentStep: pregnancyWeekIndex(
        new Date(p.due_date),
        p.lmp_date ? new Date(p.lmp_date) : null,
        now
      ),
      totalSteps: PREGNANCY_TOTAL_WEEKS,
    })),
    ...children.rows.map((c) => ({
      id: c.id,
      type: 'CHILD' as const,
      title: c.name,
      currentStep: ageInMonths(new Date(c.birth_date), now),
      totalSteps: CHILD_TOTAL_MONTHS,
    })),
  ];

  res.json(profiles);
});
