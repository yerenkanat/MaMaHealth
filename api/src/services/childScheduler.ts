import { PoolClient } from 'pg';

/** Точный возраст ребёнка в полных месяцах на дату now. */
export function ageInMonths(birthDate: Date, now: Date): number {
  let months =
    (now.getFullYear() - birthDate.getFullYear()) * 12 +
    (now.getMonth() - birthDate.getMonth());
  if (now.getDate() < birthDate.getDate()) months -= 1;
  return Math.max(0, months);
}

/**
 * Ставит в очередь медицинские алерты для ребёнка по его текущему возрасту.
 * Идемпотентно (ON CONFLICT DO NOTHING). Вызывается сразу после родов
 * и ежедневным воркером. Возвращает число реально созданных алертов.
 */
export async function scheduleChildAlerts(
  client: PoolClient,
  childId: string,
  birthDate: Date,
  runDate: Date
): Promise<number> {
  const months = ageInMonths(birthDate, runDate);
  const fireDate = runDate.toISOString().slice(0, 10);

  const { rows } = await client.query<{ id: number }>(
    `SELECT id FROM medical_protocols
      WHERE scope = 'CHILD' AND child_age_in_months = $1`,
    [months]
  );

  let created = 0;
  for (const p of rows) {
    const res = await client.query(
      `INSERT INTO scheduled_alerts
         (profile_type, profile_id, protocol_id, fire_date, status)
       VALUES ('CHILD', $1, $2, $3, 'pending')
       ON CONFLICT (profile_id, protocol_id, fire_date) DO NOTHING`,
      [childId, p.id, fireDate]
    );
    if (res.rowCount && res.rowCount > 0) created++;
  }
  return created;
}
