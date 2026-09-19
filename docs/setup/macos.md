# Installation macOS

Prérequis : macOS, 2 CPU, 4 Gio RAM, 20 Gio libres et accès Internet initial. Chemin recommandé : Homebrew + Colima + Docker CLI/Compose; Docker Desktop reste compatible. Git, Python 3.11+, `curl` et OpenSSL sont requis.

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
./scripts/setup-macos.sh --install
./scripts/verify-host.sh
docker version && docker compose version
python3 --version && curl --version && openssl version
```

Succès attendu : aucune ligne `[FAIL]`. Puis : `cd labs/shoplab && ./scripts/lab-start.sh core && ./scripts/health-check.sh core`; attendez HTTP `200`, `mode=vulnerable`.

Dépannage : `colima start` si le daemon est absent; vérifiez le lien du plugin Compose avec le script. Aide : partagez version macOS/CPU et lignes `[FAIL]` expurgées. Après `labs/shoplab/scripts/cleanup.sh`, `colima stop` est permis; n'exécutez pas `colima delete`. N'importez pas le certificat local dans le trousseau système.
