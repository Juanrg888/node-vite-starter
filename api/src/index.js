require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const errorHandler = require('./middleware/errorHandler');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ── Rutas ────────────────────────────────────────────────────────────────────
app.use('/health',  require('./routes/health'));
app.use('/ejemplo', require('./routes/ejemplo'));  // reemplazar con rutas reales

// ── Error handler ─────────────────────────────────────────────────────────────
app.use(errorHandler);

app.listen(PORT, () => console.log(`API corriendo en puerto ${PORT}`));
