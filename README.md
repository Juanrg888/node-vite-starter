# node-vite-starter

Template base para proyectos con:
- **API**: Node.js + Express + PostgreSQL
- **Frontend**: React + Vite
- **Deploy API**: VPS con Coolify (auto-deploy via GitHub Actions)
- **Deploy Front**: Vercel (auto-deploy en cada push)

## Cómo usar este template

1. Click en **"Use this template"** en GitHub
2. Nombra tu nuevo repo
3. Clona el repo nuevo
4. Sigue los pasos en `SETUP.md`

## Estructura

```
├── api/          ← Node.js + Express + PostgreSQL
├── front/        ← React + Vite
├── .github/      ← GitHub Actions (deploy a Coolify)
├── SETUP.md      ← Guía paso a paso para levantar el proyecto
└── CONTEXT.md    ← Estado vivo del proyecto (actualizar por sesión)
```
