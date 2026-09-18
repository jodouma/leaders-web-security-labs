[CmdletBinding()]
param([switch]$Install)
$ErrorActionPreference = 'Stop'
function Pass([string]$Message) { Write-Host "[PASS] $Message" -ForegroundColor Green }
function Warn([string]$Message) { Write-Warning "[WARN] $Message" }
function Fail([string]$Message) { Write-Error "[FAIL] $Message" }

if ($env:OS -ne 'Windows_NT') { Fail 'Ce script requiert Windows.' }
if ($Install) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail 'winget est requis pour l’installation automatisée.' }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements
    }
    $wslStatus = wsl.exe --status 2>&1
    if ($LASTEXITCODE -ne 0) { wsl.exe --install -d Ubuntu; Warn 'Un redémarrage Windows peut être requis.' }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        winget install --id Docker.DockerDesktop --exact --accept-source-agreements --accept-package-agreements
        Warn 'Démarrez Docker Desktop après installation; le script ne contourne pas un redémarrage requis.'
    }
}
foreach ($Name in @('git','wsl','docker')) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) { Pass "$Name présent" } else { Fail "$Name absent; relancer avec -Install" }
}
Pass 'Setup Windows terminé; lancez Verify-Host.ps1 puis les scripts du lab dans WSL2.'
