# Installation Ubuntu

Prérequis : Ubuntu 24.04/26.04, 2 CPU, 4 Gio RAM, 12 Gio libres et accès Internet pour l'installation initiale. Il faut Git, Docker + Compose v2, Python 3.11+, `curl` et OpenSSL.

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
./scripts/setup-debian.sh --install
newgrp docker   # seulement si le script vient d'ajouter votre utilisateur
./scripts/verify-host.sh
docker version && docker compose version
python3 --version && curl --version && openssl version
```

Succès attendu : aucune ligne `[FAIL]`. Démarrez ensuite `cd labs/shoplab && ./scripts/lab-start.sh core && ./scripts/health-check.sh core` et attendez HTTP `200`, `mode=vulnerable`.

Dépannage : démarrez le service Docker si `docker info` échoue; vérifiez le plugin si `docker compose` manque. Si la politique interdit le groupe `docker`, utilisez rootless Docker ou la règle locale. Aide : partagez l'OS et les lignes `[FAIL]`, après expurgation. Cleanup : `labs/shoplab/scripts/cleanup.sh`.
