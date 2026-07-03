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
  interface ReminderItem {
    id: string;
    title: string;
    category: string;
    isCritical: boolean;
    fireDate: string;
    profileType: string;
  }

  const items: ReminderItem[] = rows.map((r) => ({
    id: r.id,
    title: r.title,
    category: r.category,
    isCritical: r.is_critical,
    fireDate: new Date(r.fire_date).toISOString(),
    profileType: r.profile_type,
  }));

  // Синтетические напоминания из менструального цикла (Flo-style прогноз).
  const cycles = await pool.query<{ start_date: string }>(
    `SELECT to_char(start_date, 'YYYY-MM-DD') AS start_date
       FROM menstrual_cycles WHERE user_id = $1
      ORDER BY start_date ASC`,
    [userId]
  );
  const starts = cycles.rows.map((r) => new Date(r.start_date + 'T00:00:00Z'));
  if (starts.length > 0) {
    const DAY = 86_400_000;
    const gaps: number[] = [];
    for (let i = 1; i < starts.length; i++) {
      gaps.push(Math.round((starts[i].getTime() - starts[i - 1].getTime()) / DAY));
    }
    let avgCycle =
      gaps.length === 0 ? 28 : Math.round(gaps.reduce((a, b) => a + b, 0) / gaps.length);
    avgCycle = Math.min(35, Math.max(21, avgCycle));

    const lastStart = starts[starts.length - 1];
    const nextStart = new Date(lastStart.getTime() + avgCycle * DAY);
    const ovulation = new Date(nextStart.getTime() - 14 * DAY);
    const fertileStart = new Date(ovulation.getTime() - 4 * DAY);

    const now = Date.now();
    const withinDays = (d: Date, n: number) =>
      d.getTime() >= now - DAY && d.getTime() <= now + n * DAY;

    if (withinDays(nextStart, 7)) {
      items.push({
        id: 'cycle-period',
        title: 'Скоро месячные',
        category: 'cycle',
        isCritical: false,
        fireDate: nextStart.toISOString(),
        profileType: 'CYCLE',
      });
    }
    if (withinDays(fertileStart, 10)) {
      items.push({
        id: 'cycle-fertile',
        title: 'Приближается фертильное окно',
        category: 'cycle',
        isCritical: false,
        fireDate: fertileStart.toISOString(),
        profileType: 'CYCLE',
      });
    }
  }

  items.sort((a, b) => a.fireDate.localeCompare(b.fireDate));
  return res.json(items);
});
