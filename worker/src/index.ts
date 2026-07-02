import cron from 'node-cron';
import { pool } from './db.js';
import { scheduleChildAlerts } from './medicalScheduler.js';

const schedule = process.env.SCHEDULER_CRON ?? '0 6 * * *';

async function tick() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const created = await scheduleChildAlerts(client, new Date());
    await client.query('COMMIT');
    console.log(`[scheduler] tick done, created ${created} alert(s)`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[scheduler] tick failed', err);
  } finally {
    client.release();
  }
}

cron.schedule(schedule, tick);
console.log(`[worker] scheduler armed with cron "${schedule}"`);
