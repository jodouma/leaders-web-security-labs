# Installation Windows 11 + WSL2

## Choix recommandé

Utilisez WSL2 Ubuntu et Docker Desktop avec l'intégration WSL. Activez la virtualisation dans l'UEFI si nécessaire. Dans PowerShell administrateur :

```powershell
wsl --install -d Ubuntu
wsl --update
```

Redémarrez si Windows le demande, ouvrez Ubuntu, puis placez le dépôt dans `~/leaders-web-security-labs` (pas sous `/mnt/c`) pour éviter permissions et lenteurs. Installez Docker Desktop depuis sa source officielle, activez « Use WSL 2 based engine » puis l'intégration de la distribution Ubuntu.

Dans PowerShell, contrôle non destructif :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Verify-Host.ps1
```

Dans WSL :

```bash
./scripts/setup-debian.sh --check
./scripts/verify-host.sh
cd labs/shoplab && ./scripts/lab-start.sh core
```

N'installez pas un second daemon Docker dans WSL si Docker Desktop fournit déjà le moteur. Les URLs restent `https://127.0.0.1:8443`; le certificat est auto-signé et n'est pas importé globalement. Cleanup avant d'éteindre WSL.
