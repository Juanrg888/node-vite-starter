# CONTEXT.md — Estado vivo del proyecto

> **Para editores AI (DeepSeek, Roo, Perplexity, etc.):**
> Lee este archivo antes de tocar cualquier cosa.
> Se actualiza al final de cada sesión de trabajo.

---

## Última actualización
**Fecha:** _______  
**Sesión:** 1

---

## Descripción del proyecto

> _Describe aquí en 2-3 líneas qué hace la app y para quién._

---

## Stack

| Capa | Tecnología | Hosting |
|---|---|---|
| Frontend | React + Vite | Vercel |
| Backend/API | Node.js + Express | VPS (Coolify) |
| Base de datos | PostgreSQL | VPS (Coolify) |
| CI/CD | GitHub Actions | GitHub |

---

## Estructura del repo

```
├── api/
│   ├── src/
│   │   ├── index.js          ← Entry point. Registrar rutas nuevas aquí.
│   │   ├── db.js             ← Pool PostgreSQL
│   │   ├── routes/
│   │   │   ├── health.js
│   │   │   └── ejemplo.js    ← Reemplazar con rutas del proyecto
│   │   └── middleware/
│   │       └── errorHandler.js
│   ├── db/migrations/        ← Correr manualmente en el VPS
│   ├── Dockerfile
│   └── package.json
├── front/
│   ├── src/
│   │   ├── main.jsx
│   │   ├── App.jsx
│   │   ├── api/
│   │   │   └── client.js     ← Todas las llamadas a la API van aquí
│   │   ├── pages/
│   │   └── components/
│   └── package.json
└── .github/workflows/
    └── deploy.yml            ← Auto-deploy a Coolify en push a main
```

---

## URLs de producción

| Servicio | URL |
|---|---|
| Frontend (Vercel) | _pendiente_ |
| API (VPS) | _pendiente_ |
| Healthcheck | `<api-url>/health` |

---

## Schema de BD (estado actual)

```sql
-- Agregar tablas aquí a medida que se crean
```

---

## Endpoints de la API

| Método | Ruta | Estado |
|---|---|---|
| GET | `/health` | ✅ |

---

## Estado por feature

| Feature | BD | API | Front |
|---|---|---|---|
| Setup base | ✅ | ✅ | ✅ |

---

## En progreso ahora mismo 🚧

> _Describir qué se está construyendo en esta sesión._

---

## Próximas features

1. _Feature 1_
2. _Feature 2_

---

## Decisiones técnicas tomadas

| Decisión | Razón |
|---|---|
| Migraciones manuales | Evitar auto-run en deploy que rompa datos en prod |
