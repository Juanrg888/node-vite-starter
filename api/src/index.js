require('dotenv').config();
const express      = require('express');
const cors         = require('cors');
const errorHandler = require('./middleware/errorHandler');
const runMigrations = require('../scripts/migrate');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ── Rutas ────────────────────────────────────────────────────────────────────
app.use('/health',  require('./routes/health'));
app.use('/ejemplo', require('./routes/ejemplo'));  // reemplazar con rutas reales

// ── Error handler ─────────────────────────────────────────────────────────────
app.use(errorHandler);

// ── Arranque ───────────────────────────────────────────────────────────────────
runMigrations()
  .then(() => {
    app.listen(PORT, () => console.log(`API corriendo en puerto ${PORT}`));
  })
  .catch(err => {
    console.error('Servidor no arranca: falló una migración.', err.message);
    process.exit(1);
  });
