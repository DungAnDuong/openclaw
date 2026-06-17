# apply_openclaw_config.ps1
# Doc cac file config trong thu muc config/ va ap dung vao ~/.openclaw/openclaw.json
# Su dung: powershell -ExecutionPolicy Bypass -File scripts\apply_openclaw_config.ps1

param(
    [string]$ConfigDir = "config",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "[CONFIG] $msg" -ForegroundColor Cyan
}
function Write-OK($msg) {
    Write-Host "[OK] $msg" -ForegroundColor Green
}
function Write-Warn($msg) {
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}
function Write-Fail($msg) {
    Write-Host "[FAIL] $msg" -ForegroundColor Red
}

# --- Doc cac file config ---
$llmConfigPath = Join-Path $ConfigDir "llm_config.json"
$botConfigPath = Join-Path $ConfigDir "bot_config.json"
$appConfigPath = Join-Path $ConfigDir "app_config.json"
$pathsConfigPath = Join-Path $ConfigDir "paths.json"

foreach ($f in @($llmConfigPath, $botConfigPath, $appConfigPath, $pathsConfigPath)) {
    if (-not (Test-Path $f)) {
        Write-Fail "Khong tim thay file: $f"
        exit 1
    }
}

Write-Step "Doc cau hinh tu $ConfigDir..."

$llm = Get-Content $llmConfigPath -Raw | ConvertFrom-Json
$bot = Get-Content $botConfigPath -Raw | ConvertFrom-Json
$app = Get-Content $appConfigPath -Raw | ConvertFrom-Json
$paths = Get-Content $pathsConfigPath -Raw | ConvertFrom-Json

# --- Kiem tra api_key ---
if ($llm.api_key -eq "" -or $llm.api_key -eq "YOUR_API_KEY_HERE") {
    Write-Fail "Ban chua dien API key trong config\llm_config.json!"
    Write-Host "  Hay mo file config\llm_config.json va dien api_key that cua ban." -ForegroundColor Yellow
    exit 1
}

# --- Xac dinh thu muc openclaw config ---
$openclawConfigDir = $paths.openclaw_config_dir
if (-not $openclawConfigDir -or $openclawConfigDir -eq "") {
    $openclawConfigDir = Join-Path $env:USERPROFILE ".openclaw"
}
$openclawConfigDir = [System.Environment]::ExpandEnvironmentVariables($openclawConfigDir)

if (-not (Test-Path $openclawConfigDir)) {
    Write-Step "Tao thu muc $openclawConfigDir..."
    New-Item -ItemType Directory -Force -Path $openclawConfigDir | Out-Null
}

# --- Xac dinh thu muc workspace ---
$workspaceDir = $bot.workspace
if (-not $workspaceDir -or $workspaceDir -eq "") {
    $workspaceDir = $paths.workspace_dir
}
if (-not $workspaceDir -or $workspaceDir -eq "") {
    $workspaceDir = Join-Path $openclawConfigDir "workspace"
}
$workspaceDir = [System.Environment]::ExpandEnvironmentVariables($workspaceDir)

# --- Xay dung chuoi model theo dinh dang provider/model ---
$modelPrimary = "$($llm.provider)/$($llm.model)"
$modelConfig = @{ primary = $modelPrimary }

# Fallback model neu co
if ($llm.fallback_provider -and $llm.fallback_provider -ne "") {
    $modelConfig.fallbacks = @("$($llm.fallback_provider)/$($llm.fallback_model)")
}

# --- Xay dung agents config ---
$agentsDefaults = @{
    model = $modelConfig
    workspace = $workspaceDir.Replace("\", "/")
}

if ($app.sandbox_mode -and $app.sandbox_mode -ne "off") {
    $agentsDefaults.sandbox = @{ mode = $app.sandbox_mode }
}

# --- Xay dung openclaw.json ---
$openclawConfig = @{
    agents = @{
        defaults = $agentsDefaults
    }
}

# --- Dat bien moi truong cho API key ---
$envVarMap = @{
    "anthropic" = "ANTHROPIC_API_KEY"
    "openai"    = "OPENAI_API_KEY"
    "google"    = "GOOGLE_API_KEY"
    "xai"       = "XAI_API_KEY"
    "mistral"   = "MISTRAL_API_KEY"
    "groq"      = "GROQ_API_KEY"
}

$envVarName = $envVarMap[$llm.provider.ToLower()]
if (-not $envVarName) {
    $envVarName = ($llm.provider.ToUpper() -replace "[^A-Z0-9]", "_") + "_API_KEY"
}

Write-Step "Dat bien moi truong $envVarName..."
[System.Environment]::SetEnvironmentVariable($envVarName, $llm.api_key, "User")
$env:ANTHROPIC_API_KEY = if ($llm.provider -eq "anthropic") { $llm.api_key } else { $env:ANTHROPIC_API_KEY }
$env:OPENAI_API_KEY    = if ($llm.provider -eq "openai") { $llm.api_key } else { $env:OPENAI_API_KEY }

# Fallback api key
if ($llm.fallback_api_key -and $llm.fallback_api_key -ne "") {
    $fbEnvVar = $envVarMap[$llm.fallback_provider.ToLower()]
    if ($fbEnvVar) {
        [System.Environment]::SetEnvironmentVariable($fbEnvVar, $llm.fallback_api_key, "User")
    }
}

# --- Ghi openclaw.json ---
$openclawConfigPath = Join-Path $openclawConfigDir "openclaw.json"

if ($DryRun) {
    Write-Warn "DRY RUN - Se ghi vao: $openclawConfigPath"
    Write-Host ($openclawConfig | ConvertTo-Json -Depth 10)
} else {
    Write-Step "Ghi cau hinh vao $openclawConfigPath..."
    $openclawConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $openclawConfigPath -Encoding UTF8
    Write-OK "Da ghi openclaw.json thanh cong."
}

# --- Tra ve thong tin ---
return @{
    ConfigPath   = $openclawConfigPath
    GatewayPort  = $app.gateway_port
    GatewayHost  = $app.gateway_host
    Verbose      = $app.verbose
    EnvVarName   = $envVarName
    ModelPrimary = $modelPrimary
}
