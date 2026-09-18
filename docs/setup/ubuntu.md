# Installation Ubuntu

Testé par conception pour Ubuntu 24.04/26.04 avec Docker Compose v2; validation CI exacte : voir le workflow. Les versions de salle restent à confirmer par `verify-host.sh`.

```bash
./scripts/setup-debian.sh --install
newgrp docker   # seulement si le script vient d'ajouter votre utilisateur
./scripts/verify-host.sh
```

Le script est idempotent : il n'ajoute pas de dépôt tiers et réutilise les paquets présents. Si la politique locale interdit le groupe `docker`, utilisez le mode rootless documenté par Docker ou `sudo docker`; ne modifiez pas les scripts au hasard. Recommandez 4 Gio RAM, 2 CPU et 12 Gio libres.

Pour désinstaller, utilisez le gestionnaire de paquets selon la politique de votre machine; le projet supprime seulement ses propres ressources via `labs/shoplab/scripts/cleanup.sh`.
