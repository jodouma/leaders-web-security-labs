# Installation Kali Linux

Prérequis : Kali rolling, 2 CPU, 4 Gio RAM, 12 Gio libres et accès Internet initial. Utilisez `docker.io` et Compose des dépôts Kali; ne mélangez pas un dépôt Docker CE Ubuntu. Git, Python 3.11+, `curl` et OpenSSL sont requis.

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
./scripts/setup-debian.sh --install
newgrp docker   # si indiqué
./scripts/verify-host.sh
docker version && docker compose version
python3 --version && curl --version && openssl version
```

Succès attendu : aucune ligne `[FAIL]`. Puis : `cd labs/shoplab && ./scripts/lab-start.sh core && ./scripts/health-check.sh core`; attendez HTTP `200`, `mode=vulnerable`. Les outils offensifs préinstallés ne changent pas le scope : seulement localhost/réseau ShopLab.

Dépannage : si Compose v2 manque, installez la version recommandée par Kali, puis relancez la vérification; ne téléchargez pas un binaire non vérifié. Aide : partagez OS et lignes `[FAIL]` expurgées. Cleanup : `./scripts/cleanup.sh` depuis `labs/shoplab`.
