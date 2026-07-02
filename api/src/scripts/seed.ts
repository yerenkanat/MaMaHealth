import '../env.js';
import { pool } from '../db.js';
import { hashPassword } from '../services/auth.js';

/**
 * Демо-данные для локальной проверки: одна мама + активная беременность.
 * Идемпотентно — можно запускать повторно. Запуск: npm run seed
 */
async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query<{ id: string }>(
      `INSERT INTO users (email, full_name, district_id, role, password_hash)
       VALUES ('mom@mama.kz', 'Айгуль', 1, 'parent', $1)
       ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
       RETURNING id`,
      [hashPassword('secret123')]
    );
    const userId = rows[0].id;

    // Активная беременность: ПДР через 28 дней (~36 неделя).
    await client.query(
      `INSERT INTO pregnancies (user_id, due_date, status)
       SELECT $1, CURRENT_DATE + INTERVAL '28 days', 'active'
        WHERE NOT EXISTS (
          SELECT 1 FROM pregnancies WHERE user_id = $1 AND status = 'active'
        )`,
      [userId]
    );

    await client.query('COMMIT');
    console.log(
      `[seed] готово: mom@mama.kz / secret123 (user id=${userId}), активная беременность создана`
    );
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
