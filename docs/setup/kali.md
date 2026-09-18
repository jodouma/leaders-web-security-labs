# Installation Kali Linux

Kali rolling utilise normalement `docker.io` et le plugin Compose disponible dans ses dépôts. Ne mélangez pas le dépôt Docker CE Ubuntu avec Kali.

```bash
./scripts/setup-debian.sh --install
newgrp docker   # si indiqué
./scripts/verify-host.sh
```

Le script détecte `ID=kali`, installe les paquets de la distribution et démarre le service si systemd est actif. Une VM doit avoir au moins 2 CPU, 4 Gio et 12 Gio libres. Les outils offensifs préinstallés ne changent pas le scope : seuls localhost/réseau ShopLab sont autorisés.

Si Compose v2 n'est pas empaqueté, `[FAIL]` est intentionnel : installez la version recommandée par la documentation Kali, puis relancez la vérification. Ne téléchargez pas un binaire non vérifié pendant le cours.
