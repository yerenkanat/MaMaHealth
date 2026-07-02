import '../env.js';
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../db.js';

/** Применяет все миграции из /migrations по порядку. Запуск: npm run migrate */
async function main() {
  const here = dirname(fileURLToPath(import.meta.url));
  const migrationsDir = join(here, '../../../migrations');
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const f of files) {
    const sql = readFileSync(join(migrationsDir, f), 'utf8');
    console.log(`[migrate] applying ${f}`);
    await pool.query(sql);
  }

  await pool.end();
  console.log(`[migrate] done (${files.length} files)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
