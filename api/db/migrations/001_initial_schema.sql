-- Migración inicial — reemplazar con el schema real del proyecto
-- Ejecutar manualmente: psql $DATABASE_URL -f api/db/migrations/001_initial_schema.sql

CREATE TABLE IF NOT EXISTS ejemplo (
  id        SERIAL PRIMARY KEY,
  nombre    VARCHAR(255) NOT NULL,
  creado_en TIMESTAMP DEFAULT NOW()
);
