import { PoolClient } from 'pg';

/** Точный возраст ребёнка в полных месяцах на дату now. */
export function ageInMonths(birthDate: Date, now: Date): number {
  let months =
    (now.getFullYear() - birthDate.getFullYear()) * 12 +
    (now.getMonth() - birthDate.getMonth());
  if (now.getDate() < birthDate.getDate()) months -= 1;
  return Math.max(0, months);
}

/** Поддерживающий тон уведомления — Behavioral Nudge Engine. */
export function buildNudge(childName: string, title: string): string {
  return `💛 ${childName}, пора для важного шага: «${title}». ` +
    `Вы прекрасно справляетесь — это займёт всего пару минут заботы.`;
}

/**
 * Ядро планировщика для профилей детей. Идемпотентно за счёт
 * ON CONFLICT DO NOTHING по UNIQUE (profile_id, protocol_id, fire_date).
 * Возвращает число реально созданных алертов.
 */
export async function scheduleChildAlerts(
  client: PoolClient,
  runDate: Date
): Promise<number> {
  let created = 0;
  const fireDate = runDate.toISOString().slice(0, 10);

  const { rows: children } = await client.query<{
    id: string; name: string; birth_date: Date;
  }>(`SELECT id, name, birth_date FROM children_profiles WHERE is_active = TRUE`);

  for (const child of children) {
    const months = ageInMonths(new Date(child.birth_date), runDate);

    const { rows: protocols } = await client.query<{ id: number; title: string }>(
      `SELECT id, title FROM medical_protocols
        WHERE scope = 'CHILD' AND child_age_in_months = $1`,
      [months]
    );

    for (const p of protocols) {
      const res = await client.query(
        `INSERT INTO scheduled_alerts
           (profile_type, profile_id, protocol_id, fire_date, status)
         VALUES ('CHILD', $1, $2, $3, 'pending')
         ON CONFLICT (profile_id, protocol_id, fire_date) DO NOTHING`,
        [child.id, p.id, fireDate]
      );
      if (res.rowCount && res.rowCount > 0) {
        created++;
        // TODO: pushQueue.add({ childId: child.id, text: buildNudge(child.name, p.title) })
      }
    }
  }
  return created;
}
