# Installation Windows 11 + WSL2

## Choix recommandé

Prérequis : Windows 11, virtualisation active, 2 CPU, 4 Gio RAM, 12 Gio libres, accès Internet initial. Utilisez WSL2 Ubuntu et Docker Desktop avec intégration WSL. Git, Python 3.11+, `curl` et OpenSSL sont vérifiés dans WSL.

```powershell
wsl --install -d Ubuntu
wsl --update
```

Redémarrez si Windows le demande, ouvrez Ubuntu, puis placez le dépôt dans `~/leaders-web-security-labs` (pas sous `/mnt/c`) pour éviter permissions et lenteurs. Installez Docker Desktop depuis sa source officielle, activez « Use WSL 2 based engine » puis l'intégration de la distribution Ubuntu.

Le parcours recommandé continue dans WSL2 : clonez-y le dépôt, puis utilisez les commandes Bash ci-dessous. Les scripts PowerShell sont une alternative pour un checkout Windows distinct et accessible depuis PowerShell; ne lancez pas leurs chemins depuis le shell WSL.

Dans PowerShell, depuis la racine d'un checkout Windows, contrôle non destructif :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Verify-Host.ps1
```

Dans WSL :

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
./scripts/setup-debian.sh --check
./scripts/verify-host.sh
docker version && docker compose version
python3 --version && curl --version && openssl version
cd labs/shoplab && ./scripts/lab-start.sh core
./scripts/health-check.sh core
```

Succès attendu : aucune ligne `[FAIL]`, HTTP `200`, `mode=vulnerable`. N'installez pas un second daemon Docker dans WSL. Si Docker est inaccessible, ouvrez Docker Desktop et activez l'intégration de la distribution; gardez le dépôt sous `~/`, pas `/mnt/c`. Aide : partagez `wsl --status`, la distribution et les lignes `[FAIL]` expurgées. Exécutez `./scripts/cleanup.sh` avant d'éteindre WSL.
