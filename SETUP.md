# Guía de Setup — node-vite-starter

## 1. Variables de entorno

### API (`api/.env`)
```env
PORT=3000
DATABASE_URL=postgres://usuario:password@host:5432/mi_db
NODE_ENV=development
```

### Frontend (`front/.env`)
```env
VITE_API_URL=http://localhost:3000
```

## 2. Correr en local

```bash
# Terminal 1 — API
cd api
npm install
npm run dev

# Terminal 2 — Frontend
cd front
npm install
npm run dev
```

Frontend: http://localhost:5173  
API: http://localhost:3000  
Healthcheck: http://localhost:3000/health

## 3. Configurar Coolify (VPS)

Ver `COOLIFY_DEPLOYMENT.md` si existe, o seguir estos pasos:

1. Crear nuevo recurso en Coolify apuntando al repo
2. **Root directory**: `api`
3. **Build command**: `npm install`
4. **Start command**: `node src/index.js`
5. Agregar variable `DATABASE_URL` en Coolify
6. Copiar el webhook de Coolify

## 4. Configurar GitHub Actions

Agregar estos secrets en el repo (Settings → Secrets):

| Secret | Valor |
|---|---|
| `COOLIFY_WEBHOOK_URL` | URL del webhook de Coolify |
| `COOLIFY_TOKEN` | Token de API de Coolify |

## 5. Configurar Vercel

1. Importar repo en Vercel
2. **Root directory**: `front`
3. **Framework**: Vite
4. Agregar variable `VITE_API_URL` con la URL de tu API en producción

## 6. Correr migraciones en producción

```bash
# Conectarse al VPS y correr:
psql $DATABASE_URL -f api/db/migrations/001_initial_schema.sql
```

Cada nueva migración se corre manualmente con el mismo comando.
