# Leaders Web Security Labs — édition étudiante

Parcours local et reproductible de sécurité web : 7 TP, 4 TD, fichiers de départ et ShopLab. Les activités sont conçues pour `127.0.0.1` et un réseau Docker isolé. N'utilisez jamais les commandes ou charges sur un système tiers.

## Démarrage recommandé

1. Lisez [les règles de sécurité](SECURITY.md) et le guide de votre OS dans `docs/setup/`.
2. Exécutez le setup idempotent adapté, puis `scripts/verify-host.sh` (`scripts/Verify-Host.ps1` sous PowerShell).
3. Depuis `labs/shoplab`, lancez `./scripts/lab-start.sh core` et `./scripts/health-check.sh core`.
4. Commencez `tp/TP01_observer_le_flux.md`. Terminez toujours par `./scripts/cleanup.sh`.

```bash
# Ubuntu/Debian/Kali/WSL2
./scripts/setup-debian.sh --check
# macOS
./scripts/setup-macos.sh --check
# validation commune
./scripts/verify-host.sh
```

Chaque vérificateur affiche `[PASS]`, `[WARN]` ou `[FAIL]`. `WARN` signifie qu'une validation manuelle est nécessaire; `FAIL` bloque le lab. Les images doivent être préchargées si la salle n'a pas d'accès Internet.

## Arborescence

- `docs/setup/` : installation Windows/WSL2, Ubuntu, Kali et macOS; `docs/` contient dépannage et remise ;
- `tp/`, `td/` : sujets étudiants ;
- `starter-files/` : code à compléter et tests de départ ;
- `labs/shoplab/` : application locale, Compose et scripts de cycle de vie ;
- `scripts/` : setup et vérification hôte ;
- `.github/workflows/student-labs.yml` : contrôles statiques sans attaque réseau.

Contenu pédagogique sous CC BY-NC-SA 4.0 (`LICENSE-CONTENT.md`); code sous MIT (`LICENSE-CODE.md`). Établissement, semestre et charte visuelle : **À confirmer**.
