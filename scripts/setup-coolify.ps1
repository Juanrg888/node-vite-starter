<#
.SYNOPSIS
  Crea un proyecto completo en Coolify desde cero en un solo comando.
  Al terminar: un git push deploya automaticamente en Coolify.

.USAGE
  .\scripts\setup-coolify.ps1 `
    -RepoName    "mi-nuevo-app" `
    -CoolifyToken "tu-token-coolify" `
    -GitHubToken  "ghp_xxxx"

.NOTES
  Prereq: La GitHub App "coolify-gastos" debe tener acceso al repo.
  Agregarlo en: GitHub > Settings > Applications > coolify-gastos > Configure > Add repository
#>

param(
    [Parameter(Mandatory)][string]$RepoName,
    [Parameter(Mandatory)][string]$CoolifyToken,
    [Parameter(Mandatory)][string]$GitHubToken,
    [string]$GitHubOwner = "Juanrg888",
    [string]$CoolifyURL  = "http://5.78.100.50:8000",
    [string]$GitBranch   = "main",
    [string]$ApiPort     = "3000"
)

$ErrorActionPreference = "Stop"

$hC = @{ Authorization = "Bearer $CoolifyToken"; "Content-Type" = "application/json" }
$hG = @{
    Authorization          = "Bearer $GitHubToken"
    "Content-Type"         = "application/json"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Write-Step { param($n, $msg) Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  --  $msg" -ForegroundColor Gray }

Write-Host "`nSetup Coolify -- $RepoName`n" -ForegroundColor Yellow

# -- 1. Auto-detectar servidor --
Write-Step "1/7" "Detectando servidor Coolify..."
$servers = Invoke-RestMethod -Uri "$CoolifyURL/api/v1/servers" -Headers $hC
$server  = if ($servers -is [array]) { $servers | Select-Object -First 1 } else { $servers }
if (-not $server -or -not $server.uuid) { throw "No se encontro ningun servidor en Coolify." }
$serverUUID = $server.uuid
Write-OK "Servidor: $($server.name) ($serverUUID)"

# -- 2. Auto-detectar GitHub App --
Write-Step "2/7" "Detectando GitHub App..."
$ghApps = Invoke-RestMethod -Uri "$CoolifyURL/api/v1/github-apps" -Headers $hC
$ghApp  = if ($ghApps -is [array]) {
    $ghApps | Where-Object { $_.is_public -eq $false } | Select-Object -First 1
} else { $ghApps }
if (-not $ghApp -or -not $ghApp.uuid) { throw "No se encontro GitHub App privada en Coolify." }
$ghAppUUID = $ghApp.uuid
Write-OK "GitHub App: $($ghApp.name) ($ghAppUUID)"

# -- 3. Crear proyecto --
Write-Step "3/7" "Creando proyecto '$RepoName'..."
$body        = @{ name = $RepoName; description = "Creado por setup-coolify.ps1 el $(Get-Date -Format 'yyyy-MM-dd')" } | ConvertTo-Json
$project     = Invoke-RestMethod -Uri "$CoolifyURL/api/v1/projects" -Method POST -Headers $hC -Body $body
$projectUUID = $project.uuid
Write-OK "Proyecto: $projectUUID"

# -- 4. Crear base de datos PostgreSQL --
# Endpoint correcto: POST /api/v1/databases/postgresql (tipo va en la URL, no en el body)
Write-Step "4/7" "Creando PostgreSQL..."
$dbName     = ($RepoName -replace "[^a-zA-Z0-9]", "_")
$dbPassword = -join ((65..90 + 97..122 + 48..57) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
$body = @{
    name             = "$RepoName-db"
    project_uuid     = $projectUUID
    server_uuid      = $serverUUID
    environment_name = "production"
    postgres_user    = "appuser"
    postgres_password = $dbPassword
    postgres_db      = $dbName
} | ConvertTo-Json
$db     = Invoke-RestMethod -Uri "$CoolifyURL/api/v1/databases/postgresql" -Method POST -Headers $hC -Body $body
$dbUUID = $db.uuid
Write-OK "BD: $dbUUID"

# -- 5. Crear aplicacion --
Write-Step "5/7" "Creando aplicacion..."
$body = @{
    type                = "private-github-app"
    name                = "$RepoName-api"
    project_uuid        = $projectUUID
    server_uuid         = $serverUUID
    environment_name    = "production"
    git_repository      = "$GitHubOwner/$RepoName"
    git_branch          = $GitBranch
    build_pack          = "dockerfile"
    dockerfile_location = "/api/Dockerfile"
    github_app_uuid     = $ghAppUUID
    ports_exposes       = $ApiPort
} | ConvertTo-Json
$app     = Invoke-RestMethod -Uri "$CoolifyURL/api/v1/applications" -Method POST -Headers $hC -Body $body
$appUUID = $app.uuid
Write-OK "App: $appUUID"

# -- 6. Variables de entorno (runtime-only) --
Write-Step "6/7" "Configurando variables de entorno..."
$envVars = @(
    @{ key = "NODE_ENV";     value = "production";               is_build_time = $false },
    @{ key = "PORT";         value = $ApiPort;                   is_build_time = $false },
    @{ key = "DATABASE_URL"; value = '${Postgres.DATABASE_URL}'; is_build_time = $false }
)
foreach ($var in $envVars) {
    Invoke-RestMethod -Uri "$CoolifyURL/api/v1/applications/$appUUID/envs" `
        -Method POST -Headers $hC -Body ($var | ConvertTo-Json) | Out-Null
    Write-Info "$($var.key)"
}
Write-OK "Variables configuradas"

# -- 7. Actualizar deploy.yml y secret en GitHub --
Write-Step "7/7" "Actualizando GitHub..."

$deployUrl = "$CoolifyURL/api/v1/deploy?uuid=$appUUID&force=false"

$lines = @(
    "name: Deploy to Coolify",
    "on:",
    "  push:",
    "    branches: [main]",
    "jobs:",
    "  deploy:",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - name: Check secret",
    "        id: check",
    "        run: |",
    '          if [ -z "${{ secrets.COOLIFY_TOKEN }}" ]; then',
    '            echo "skip=true" >> $GITHUB_OUTPUT',
    "          else",
    '            echo "skip=false" >> $GITHUB_OUTPUT',
    "          fi",
    "      - name: Trigger Coolify Deploy",
    "        if: steps.check.outputs.skip == 'false'",
    "        run: |",
    "          curl -f -X POST \",
    '            -H "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}" \',
    "            `"$deployUrl`""
)
$deployYaml  = $lines -join "`n"
$encodedYaml = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($deployYaml))

try {
    $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubOwner/$RepoName/contents/.github/workflows/deploy.yml" -Headers $hG
    $fileSha  = $existing.sha
} catch { $fileSha = $null }

$ghBody = @{ message = "ci: configure Coolify deploy URL"; content = $encodedYaml }
if ($fileSha) { $ghBody.sha = $fileSha }
Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubOwner/$RepoName/contents/.github/workflows/deploy.yml" `
    -Method PUT -Headers $hG -Body ($ghBody | ConvertTo-Json) | Out-Null
Write-OK "deploy.yml actualizado (UUID: $appUUID)"

# Setear COOLIFY_TOKEN como GitHub Actions Secret
$ghCLI = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
if ($ghCLI) {
    $CoolifyToken | gh secret set COOLIFY_TOKEN --repo "$GitHubOwner/$RepoName"
    Write-OK "Secret COOLIFY_TOKEN seteado via gh CLI"
} else {
    Write-Host "`n  PASO MANUAL REQUERIDO:" -ForegroundColor Yellow
    Write-Host "  1. Ve a: https://github.com/$GitHubOwner/$RepoName/settings/secrets/actions" -ForegroundColor White
    Write-Host "  2. New secret  Nombre: COOLIFY_TOKEN  Valor: $CoolifyToken" -ForegroundColor White
}

# -- Resumen --
Write-Host "`n----------------------------------------------" -ForegroundColor Yellow
Write-Host "Setup completo -- $RepoName" -ForegroundColor Green
Write-Host "----------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Proyecto UUID  : $projectUUID"
Write-Host "  App UUID       : $appUUID"
Write-Host "  DB UUID        : $dbUUID"
Write-Host "  DB Password    : $dbPassword  (guardala en tu gestor)"
Write-Host ""
Write-Host "  Panel Coolify  : $CoolifyURL" -ForegroundColor Cyan
Write-Host "  Repo GitHub    : https://github.com/$GitHubOwner/$RepoName" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Proximo paso   -> git push origin main" -ForegroundColor Green
Write-Host "  Eso es todo. La API se deploya sola." -ForegroundColor Gray
Write-Host ""
