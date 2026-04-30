require('dotenv').config();
const fs   = require('fs');
const path = require('path');
const { Client } = require('pg');

async function runMigrations() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });

  await client.connect();

  try {
    // Tabla de control — se crea sola si no existe
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id          SERIAL PRIMARY KEY,
        filename    VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);

    const migrationsDir = path.join(__dirname, '..', 'db', 'migrations');

    if (!fs.existsSync(migrationsDir)) {
      console.log('[migrations] No existe carpeta de migraciones, nada por ejecutar.');
      return;
    }

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      const { rowCount } = await client.query(
        'SELECT 1 FROM schema_migrations WHERE filename = $1 LIMIT 1', [file]
      );

      if (rowCount > 0) {
        console.log(`[migrations] Ya aplicada: ${file}`);
        continue;
      }

      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
      console.log(`[migrations] Ejecutando: ${file}`);

      await client.query('BEGIN');
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [file]);
      await client.query('COMMIT');

      console.log(`[migrations] Aplicada: ${file}`);
    }

    console.log('[migrations] Completadas.');
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('[migrations] Error — ROLLBACK ejecutado:', err.message);
    throw err;  // el servidor NO arranca si una migración falla
  } finally {
    await client.end();
  }
}

// Permite correr manualmente: node scripts/migrate.js
if (require.main === module) {
  runMigrations().catch(err => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = runMigrations;
