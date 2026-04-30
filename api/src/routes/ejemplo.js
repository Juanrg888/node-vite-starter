/**
 * Ruta de ejemplo — reemplazar o eliminar.
 * GET  /ejemplo       → lista todos
 * POST /ejemplo       → crea uno
 * DELETE /ejemplo/:id → elimina uno
 */
const router = require('express').Router();
const db     = require('../db');

router.get('/', async (req, res, next) => {
  try {
    const { rows } = await db.query('SELECT * FROM ejemplo ORDER BY id DESC');
    res.json(rows);
  } catch (err) { next(err); }
});

router.post('/', async (req, res, next) => {
  try {
    const { nombre } = req.body;
    if (!nombre) return res.status(400).json({ error: 'nombre es requerido' });
    const { rows } = await db.query(
      'INSERT INTO ejemplo (nombre) VALUES ($1) RETURNING *', [nombre]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const { rowCount } = await db.query('DELETE FROM ejemplo WHERE id = $1', [req.params.id]);
    if (!rowCount) return res.status(404).json({ error: 'No encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
});

module.exports = router;
