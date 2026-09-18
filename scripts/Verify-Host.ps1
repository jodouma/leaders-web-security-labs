$ErrorActionPreference = 'Continue'
$script:Pass = 0; $script:Warn = 0; $script:Fail = 0
function Add-Pass([string]$Message) { $script:Pass++; Write-Host "[PASS] $Message" -ForegroundColor Green }
function Add-Warn([string]$Message) { $script:Warn++; Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Add-Fail([string]$Message) { $script:Fail++; Write-Host "[FAIL] $Message" -ForegroundColor Red }

foreach ($Name in @('git','wsl','docker')) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) { Add-Pass "$Name disponible" } else { Add-Fail "$Name absent" }
}
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $Version = wsl.exe --version 2>&1
    if ($LASTEXITCODE -eq 0) { Add-Pass 'WSL répond' } else { Add-Fail 'WSL ne répond pas' }
}
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { Add-Pass 'daemon Docker accessible' } else { Add-Fail 'daemon Docker inaccessible' }
    docker compose version *> $null
    if ($LASTEXITCODE -eq 0) { Add-Pass 'Compose v2 accessible' } else { Add-Fail 'Compose v2 absent' }
}
$Drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot((Get-Location).Path).Substring(0,1)) -ErrorAction SilentlyContinue
if ($Drive -and $Drive.Free -ge 6GB) { Add-Pass 'au moins 6 Gio libres' } else { Add-Warn 'espace libre inférieur à 6 Gio ou non mesurable' }
Write-Host "Résumé: PASS=$script:Pass WARN=$script:Warn FAIL=$script:Fail"
if ($script:Fail -gt 0) { exit 1 }
