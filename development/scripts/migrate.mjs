import './workspace.mjs';
import mysql from 'mysql2/promise';
import { readdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
export async function migrate(db) {
  await db.query('CREATE TABLE IF NOT EXISTS schema_migrations(version VARCHAR(80) PRIMARY KEY, checksum CHAR(64) NOT NULL, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB');
  const [[lock]] = await db.query("SELECT GET_LOCK('mx_migrate',10) AS acquired");
  if (!lock.acquired) throw Error('Migration já em andamento');
  try {
    for (const file of (await readdir(new URL('../migrations/',import.meta.url))).filter(f=>f.endsWith('.sql')).sort()) {
      const sql = await readFile(new URL('../migrations/'+file,import.meta.url),'utf8');
      const hash = createHash('sha256').update(sql).digest('hex');
      const [rows] = await db.execute('SELECT checksum FROM schema_migrations WHERE version=?',[file]);
      if (rows.length) { if(rows[0].checksum!==hash) throw Error('Migration aplicada foi alterada: '+file); continue; }
      // DDL MySQL faz commit implícito. Statements idempotentes permitem retomar falha parcial.
      for(const statement of sql.split(';').map(s=>s.trim()).filter(Boolean)) await db.query(statement);
      await db.execute('INSERT INTO schema_migrations(version,checksum) VALUES (?,?)',[file,hash]);
    }
  } finally { await db.query("SELECT RELEASE_LOCK('mx_migrate')"); }
}
if(process.argv[1]?.endsWith('migrate.mjs')) {
  if(!process.env.MX_DATABASE_URL) throw Error('Defina MX_DATABASE_URL para o banco de destino');
  const db=await mysql.createConnection(process.env.MX_DATABASE_URL);
  try { await migrate(db); console.log('Migrations verificadas/aplicadas'); } finally { await db.end(); }
}
