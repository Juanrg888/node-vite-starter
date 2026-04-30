# TROUBLESHOOTING.md — Errores comunes y soluciones

> Hallazgos reales documentados durante el primer deploy de un proyecto Node.js + Coolify + Vercel.
> Lee esto antes de debuggear — probablemente ya fue resuelto.

---

## 1. GitHub Actions no dispara — workflow ignorado silenciosamente

**Síntoma:** Haces push, Vercel deploya, pero Coolify no hace nada. No aparece el workflow en la pestaña Actions de GitHub.

**Causa:** El archivo `deploy.yml` está en la ruta incorrecta.

GitHub Actions **solo detecta workflows en `.github/workflows/`**. En cualquier otra ruta el archivo es ignorado sin error ni advertencia.

```
❌  workflows/deploy.yml          ← ignorado
❌  .github/deploy.yml             ← ignorado
✅  .github/workflows/deploy.yml   ← correcto
```

**Solución:** Verificar la ruta exacta. En Windows/PowerShell, crear el archivo así:

```powershell
New-Item -ItemType Directory -Force -Path .github/workflows
@'
yaml content here
'@ | Set-Content .github/workflows/deploy.yml
```

> **Nota Windows:** No usar `cat <<EOF` — es sintaxis bash y no funciona en PowerShell.

---

## 2. curl en GitHub Actions devuelve error o el header no llega

**Síntoma:** El workflow corre pero Coolify devuelve 401 o el curl falla.

**Causa:** Curl multilínea mal indentado en YAML hace que el flag `-H` se interprete como argumento suelto, no como header del curl.

```yaml
# ❌ MAL — el -H queda fuera del curl
run: curl -X POST "https://..."
  -H "Authorization: Bearer ${{ secrets.TOKEN }}"

# ✅ BIEN — usar bloque | con \
run: |
  curl -f -X POST \
    -H "Authorization: Bearer ${{ secrets.TOKEN }}" \
    "https://..."
```

---

## 3. Token de Coolify inválido (401)

**Síntoma:** El curl llega a Coolify pero responde 401 Unauthorized.

**Causas posibles:**
- El secret de GitHub tiene un token viejo o copiado incorrectamente
- El token fue generado con permisos insuficientes

**Solución:**
1. En Coolify: **Security → API Tokens** → generar token nuevo con permiso `deploy`
2. En GitHub: **Settings → Secrets and variables → Actions** → actualizar `COOLIFY_TOKEN`
3. Hacer un push de prueba para verificar

---

## 4. `NODE_ENV=production` rompe el build

**Síntoma:** El build falla con `Cannot find module` o errores de dependencias faltantes.

**Causa:** Si `NODE_ENV=production` está disponible en **build time**, `npm install` omite las `devDependencies`. Esto rompe proyectos que usan TypeScript, Webpack, Vite u otras herramientas de build.

**Solución en Coolify:** Marcar `NODE_ENV` como **Runtime only** (no disponible en build time). El switch está en la UI de variables de entorno de la app.

---

## 5. `DATABASE_URL` — variable interna de Coolify

**Síntoma:** La app no conecta a la BD aunque ambas estén en Coolify.

**Causa:** Al usar la variable `DATABASE_URL` directamente con el valor string, puede cambiar si Coolify recrea la BD.

**Solución:** Usar la referencia dinámica de Coolify en vez del valor hardcodeado:

```
${{Postgres.DATABASE_URL}}
```

Esta sintaxis se copia desde la UI de la base de datos en Coolify y siempre apunta al valor actual.

---

## 6. Migraciones SQL fallan al correrlas en local contra producción

**Síntoma:** `ENOTFOUND` al intentar correr `npm run db:migrate` localmente.

**Causa:** El `DATABASE_URL` del VPS usa un hostname interno de Coolify que solo resuelve desde dentro del servidor, no desde tu máquina local.

**Regla:** No correr migraciones localmente contra la BD de producción. El flujo correcto:

```
git push → Coolify deploya → runMigrations() corre automáticamente al arrancar el servidor
```

Ver `SETUP.md` para la arquitectura de migraciones automáticas.

---

## 7. `Cannot find module 'dotenv'` al correr scripts de la API

**Causa:** Se está corriendo el comando desde la raíz del repo en vez de desde `api/`.

```bash
# ❌ MAL
npm run dev

# ✅ BIEN
cd api && npm run dev
# o
npm run dev --prefix api
```

---

## 8. Repos privados — Coolify necesita GitHub App (no PAT)

**Síntoma:** Coolify no encuentra el repo o da error de acceso.

**Causa:** Coolify requiere una **GitHub App** para acceder a repos privados. Un Personal Access Token (PAT) no funciona para el source tracking.

**Solución:**
1. En Coolify: **Sources → GitHub App →** conectar o reutilizar la app existente
2. En GitHub: ir a la instalación de la GitHub App → agregar el nuevo repo
3. Una sola GitHub App sirve para todos los proyectos del mismo usuario/org

---

## 9. El workflow corre pero falla con exit code 3 (curl)

**Causa:** El secret `COOLIFY_WEBHOOK_URL` está vacío o no configurado. Curl recibe una URL en blanco y falla con "URL malformada".

**Solución:** Configurar los secrets antes del primer push (ver `SETUP.md` sección 4), o verificar que el workflow incluya el guard de secrets vacíos:

```yaml
- name: Check secrets
  id: check
  run: |
    if [ -z "${{ secrets.COOLIFY_WEBHOOK_URL }}" ]; then
      echo "Secret no configurado — saltando deploy."
      echo "skip=true" >> $GITHUB_OUTPUT
    else
      echo "skip=false" >> $GITHUB_OUTPUT
    fi

- name: Trigger deploy
  if: steps.check.outputs.skip == 'false'
  run: |
    curl ...
```

---

## 10. Verificar que todo está funcionando

Después del primer deploy exitoso, verificar en orden:

```bash
# 1. API responde
curl https://tu-api-url/health
# Esperado: { "status": "ok", "db": "connected" }

# 2. GitHub Actions corre en verde
# GitHub → repo → Actions → último workflow

# 3. Vercel deploya el front
# Vercel dashboard → último deployment en estado Ready

# 4. Push de prueba dispara ambos
git commit --allow-empty -m "test: verify dual deploy"
git push origin main
```
