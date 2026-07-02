import { pool } from './db.js';
import { scheduleChildAlerts } from './medicalScheduler.js';

/** Одноразовый прогон планировщика (npm run run:once). */
async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const created = await scheduleChildAlerts(client, new Date());
    await client.query('COMMIT');
    console.log(`[scheduler] created ${created} alert(s)`);
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
