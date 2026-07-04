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

const MOODS = new Set(['great', 'good', 'ok', 'low', 'bad']);

// Ежедневный лог самочувствия: последние 30 записей (новые сверху).
meRouter.get('/daily', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    log_date: string;
    mood: string | null;
    symptoms: string[];
    note: string | null;
  }>(
    `SELECT to_char(log_date, 'YYYY-MM-DD') AS log_date, mood, symptoms, note
       FROM daily_logs WHERE user_id = $1
      ORDER BY log_date DESC LIMIT 30`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({
      date: r.log_date,
      mood: r.mood,
      symptoms: r.symptoms,
      note: r.note,
    }))
  );
});

// Создать/обновить запись за день (upsert по дате).
meRouter.post('/daily', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { date, mood, symptoms, note } = req.body ?? {};
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'bad_date' });
  }
  if (mood != null && !MOODS.has(mood)) {
    return res.status(400).json({ error: 'bad_mood' });
  }
  const symptomList = Array.isArray(symptoms)
    ? symptoms.filter((s): s is string => typeof s === 'string').slice(0, 20)
    : [];
  const noteText = typeof note === 'string' ? note.slice(0, 500) : null;
  await pool.query(
    `INSERT INTO daily_logs (user_id, log_date, mood, symptoms, note)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (user_id, log_date) DO UPDATE
       SET mood = EXCLUDED.mood,
           symptoms = EXCLUDED.symptoms,
           note = EXCLUDED.note,
           updated_at = now()`,
    [userId, date, mood ?? null, symptomList, noteText]
  );
  return res.status(204).end();
});

// Состояние чеклиста по ключу списка: отмеченные пункты.
meRouter.get('/checklist/:key', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{ items: string[] }>(
    `SELECT items FROM checklist_state WHERE user_id = $1 AND list_key = $2`,
    [userId, req.params.key]
  );
  return res.json({ items: rows[0]?.items ?? [] });
});

meRouter.post('/checklist/:key', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { items } = req.body ?? {};
  const list = Array.isArray(items)
    ? items.filter((s): s is string => typeof s === 'string').slice(0, 200)
    : [];
  await pool.query(
    `INSERT INTO checklist_state (user_id, list_key, items)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, list_key) DO UPDATE
       SET items = EXCLUDED.items, updated_at = now()`,
    [userId, req.params.key, list]
  );
  return res.status(204).end();
});

// История чата с MaMa AI (последние 50, в хронологическом порядке).
meRouter.get('/chat', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{ role: string; text: string }>(
    `SELECT role, text FROM (
       SELECT role, text, created_at FROM chat_messages
        WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50
     ) t ORDER BY created_at ASC`,
    [userId]
  );
  return res.json(rows.map((r) => ({ role: r.role, text: r.text })));
});

meRouter.post('/chat', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { role, text } = req.body ?? {};
  if ((role !== 'user' && role !== 'assistant') || typeof text !== 'string' || !text.trim()) {
    return res.status(400).json({ error: 'bad_input' });
  }
  await pool.query(
    `INSERT INTO chat_messages (user_id, role, text) VALUES ($1, $2, $3)`,
    [userId, role, text.slice(0, 4000)]
  );
  return res.status(204).end();
});

// Трекинг цикла: список залогированных месячных (новые сверху).
meRouter.get('/cycles', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{ start_date: string; end_date: string | null }>(
    `SELECT to_char(start_date, 'YYYY-MM-DD') AS start_date,
            to_char(end_date, 'YYYY-MM-DD') AS end_date
       FROM menstrual_cycles WHERE user_id = $1
      ORDER BY start_date DESC LIMIT 24`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({ startDate: r.start_date, endDate: r.end_date }))
  );
});

// Отметить месячные (start + опционально end). Upsert по дате начала.
meRouter.post('/cycles', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { startDate, endDate } = req.body ?? {};
  const dateRe = /^\d{4}-\d{2}-\d{2}$/;
  if (typeof startDate !== 'string' || !dateRe.test(startDate)) {
    return res.status(400).json({ error: 'bad_start' });
  }
  const end =
    typeof endDate === 'string' && dateRe.test(endDate) ? endDate : null;
  if (end !== null && end < startDate) {
    return res.status(400).json({ error: 'end_before_start' });
  }
  await pool.query(
    `INSERT INTO menstrual_cycles (user_id, start_date, end_date)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, start_date) DO UPDATE SET end_date = EXCLUDED.end_date`,
    [userId, startDate, end]
  );
  return res.status(204).end();
});

// Онбординг: задать/обновить ПДР активной беременности (пересчёт недели — в /profiles).
meRouter.post('/pregnancy', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { dueDate } = req.body ?? {};
  if (typeof dueDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) {
    return res.status(400).json({ error: 'bad_date' });
  }
  const updated = await pool.query(
    `UPDATE pregnancies SET due_date = $2
      WHERE user_id = $1 AND status = 'active'`,
    [userId, dueDate]
  );
  if (updated.rowCount === 0) {
    await pool.query(
      `INSERT INTO pregnancies (user_id, due_date, status)
       VALUES ($1, $2, 'active')`,
      [userId, dueDate]
    );
  }
  return res.status(204).end();
});

// Трекер воды: количество стаканов за сегодня.
meRouter.get('/water', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{ glasses: number }>(
    `SELECT glasses FROM water_logs
      WHERE user_id = $1 AND log_date = CURRENT_DATE`,
    [userId]
  );
  return res.json({ glasses: rows[0]?.glasses ?? 0 });
});

meRouter.post('/water', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { glasses } = req.body ?? {};
  if (typeof glasses !== 'number' || glasses < 0) {
    return res.status(400).json({ error: 'bad_input' });
  }
  const clamped = Math.min(30, Math.round(glasses));
  await pool.query(
    `INSERT INTO water_logs (user_id, log_date, glasses)
     VALUES ($1, CURRENT_DATE, $2)
     ON CONFLICT (user_id, log_date)
       DO UPDATE SET glasses = EXCLUDED.glasses, updated_at = now()`,
    [userId, clamped]
  );
  return res.json({ glasses: clamped });
});

// Проактивные подсказки ассистента, вычисленные из данных пользователя.
meRouter.get('/insights', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const insights: { text: string; emoji: string }[] = [];
  const DAY = 86_400_000;
  const now = Date.now();

  // 1) Прогноз цикла
  const cyc = await pool.query<{ start_date: string }>(
    `SELECT to_char(start_date, 'YYYY-MM-DD') AS start_date
       FROM menstrual_cycles WHERE user_id = $1 ORDER BY start_date ASC`,
    [userId]
  );
  const starts = cyc.rows.map((r) => new Date(r.start_date + 'T00:00:00Z'));
  if (starts.length > 0) {
    const gaps: number[] = [];
    for (let i = 1; i < starts.length; i++) {
      gaps.push(Math.round((starts[i].getTime() - starts[i - 1].getTime()) / DAY));
    }
    let avg = gaps.length ? Math.round(gaps.reduce((a, b) => a + b, 0) / gaps.length) : 28;
    avg = Math.min(35, Math.max(21, avg));
    const next = new Date(starts[starts.length - 1].getTime() + avg * DAY);
    const days = Math.round((next.getTime() - now) / DAY);
    if (days >= 0 && days <= 3) {
      insights.push({
        text: days === 0 ? 'Месячные ожидаются сегодня.' : `До месячных ~${days} дн. — подготовьтесь заранее.`,
        emoji: '🩸',
      });
    } else if (days < 0 && days >= -7) {
      insights.push({ text: `Задержка ${-days} дн. Если беспокоит — сделайте тест или загляните к врачу.`, emoji: '📅' });
    }
    const ovulation = new Date(next.getTime() - 14 * DAY);
    const fertileStart = ovulation.getTime() - 4 * DAY;
    const fertileEnd = ovulation.getTime() + DAY;
    if (now >= fertileStart && now <= fertileEnd) {
      insights.push({ text: 'Сейчас фертильные дни — благоприятное время для зачатия.', emoji: '🌱' });
    }
  }

  // 2) Частый симптом за последние записи
  const logs = await pool.query<{ symptoms: string[] }>(
    `SELECT symptoms FROM daily_logs WHERE user_id = $1 ORDER BY log_date DESC LIMIT 7`,
    [userId]
  );
  const symCount = new Map<string, number>();
  for (const row of logs.rows) {
    for (const s of row.symptoms) symCount.set(s, (symCount.get(s) ?? 0) + 1);
  }
  const RU: Record<string, string> = {
    nausea: 'тошноту', fatigue: 'усталость', headache: 'головную боль',
    backache: 'боль в спине', cravings: 'тягу к еде', swelling: 'отёки',
    heartburn: 'изжогу', insomnia: 'бессонницу', cramps: 'спазмы', dizziness: 'головокружение',
  };
  let topSym: string | null = null;
  let topN = 0;
  for (const [s, n] of symCount) {
    if (n >= 3 && n > topN) { topSym = s; topN = n; }
  }
  if (topSym) {
    insights.push({
      text: `Вы часто отмечаете ${RU[topSym] ?? topSym} (${topN} дн.). Спросите меня, как облегчить это.`,
      emoji: '💡',
    });
  }

  // 3) Стрик
  const u = await pool.query<{ streak: number }>(
    `SELECT streak FROM users WHERE id = $1`,
    [userId]
  );
  const streak = u.rows[0]?.streak ?? 0;
  if (streak >= 3) {
    insights.push({ text: `Отличная серия — ${streak} дн. подряд! Так держать 💪`, emoji: '🔥' });
  }

  return res.json(insights.slice(0, 3));
});

const BABY_TYPES = new Set(['feed', 'sleep', 'diaper']);

// Дневник малыша: последние события (кормления/сон/подгузники).
meRouter.get('/baby-events', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { rows } = await pool.query<{
    id: string;
    type: string;
    detail: string | null;
    happened_at: Date;
  }>(
    `SELECT id, type, detail, happened_at
       FROM baby_events WHERE user_id = $1
      ORDER BY happened_at DESC LIMIT 50`,
    [userId]
  );
  return res.json(
    rows.map((r) => ({
      id: r.id,
      type: r.type,
      detail: r.detail,
      happenedAt: r.happened_at,
    }))
  );
});

meRouter.post('/baby-events', verifyJwt, async (req, res) => {
  const userId = req.auth!.userId;
  const { type, detail } = req.body ?? {};
  if (!BABY_TYPES.has(type)) {
    return res.status(400).json({ error: 'bad_type' });
  }
  const detailText =
    typeof detail === 'string' ? detail.slice(0, 100) : null;
  const { rows } = await pool.query<{ id: string; happened_at: Date }>(
    `INSERT INTO baby_events (user_id, type, detail)
     VALUES ($1, $2, $3) RETURNING id, happened_at`,
    [userId, type, detailText]
  );
  return res.status(201).json({
    id: rows[0].id,
    type,
    detail: detailText,
    happenedAt: rows[0].happened_at,
  });
});
