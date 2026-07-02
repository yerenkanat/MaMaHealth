import '../env.js';
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../db.js';

/** Применяет новые миграции из /migrations по порядку (с трекингом). npm run migrate */
async function main() {
  const here = dirname(fileURLToPath(import.meta.url));
  const migrationsDir = join(here, '../../../migrations');

  await pool.query(
    `CREATE TABLE IF NOT EXISTS schema_migrations (
       name text PRIMARY KEY,
       applied_at timestamptz NOT NULL DEFAULT now()
     )`
  );
  const applied = new Set(
    (await pool.query<{ name: string }>('SELECT name FROM schema_migrations')).rows.map(
      (r) => r.name
    )
  );

  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  let count = 0;
  for (const f of files) {
    if (applied.has(f)) {
      console.log(`[migrate] skip ${f} (applied)`);
      continue;
    }
    const sql = readFileSync(join(migrationsDir, f), 'utf8');
    console.log(`[migrate] applying ${f}`);
    await pool.query('BEGIN');
    try {
      await pool.query(sql);
      await pool.query('INSERT INTO schema_migrations (name) VALUES ($1)', [f]);
      await pool.query('COMMIT');
      count++;
    } catch (e) {
      await pool.query('ROLLBACK');
      throw e;
    }
  }

  await pool.end();
  console.log(`[migrate] done (${count} new)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
