# Leaders Web Security Labs — édition étudiante

Parcours local et reproductible de sécurité web : 7 TP, 4 TD, fichiers de départ et ShopLab. Les activités sont conçues pour `127.0.0.1` et un réseau Docker isolé. N'utilisez jamais les commandes ou charges sur un système tiers.

## Préparation avant le cours

Installez d'abord Git avec le gestionnaire officiel de votre OS, puis clonez le dépôt public :

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
```

Prérequis du cœur du lab : Git, Docker avec Compose v2, `curl`, OpenSSL et Python 3.11+. Prévoyez 2 CPU, 4 Gio de RAM et 12 Gio libres; le setup macOS réserve un disque Colima de 20 Gio. Suivez ensuite le guide correspondant : [Windows 11 + WSL2](docs/setup/windows-wsl2.md), [Ubuntu](docs/setup/ubuntu.md), [Kali Linux](docs/setup/kali.md) ou [macOS](docs/setup/macos.md).

Depuis la racine du dépôt, lancez `./scripts/verify-host.sh` sous Linux, WSL2 ou macOS. Dans un checkout Windows accessible depuis PowerShell, utilisez `Set-ExecutionPolicy -Scope Process Bypass`, puis `.\scripts\Verify-Host.ps1`. En cas de `[FAIL]`, ne démarrez pas ShopLab : envoyez une capture complète de l'erreur et le nom/version de votre OS, après avoir masqué toute donnée personnelle ou tout jeton.

## Supports du jour

- [Présentation S01–S02 — éthique, scope, preuve et chemin d'une requête](course-materials/presentations/S01-S02.pdf)
- [Guide TP01 — installer ShopLab et observer une requête (PDF)](course-materials/tp-guides/TP01_observer_le_flux.pdf)
- [Guide TP02 — session, cookie, rotation, logout et CSRF (PDF)](course-materials/tp-guides/TP02_session_cookie_csrf.pdf)

Tous les PDF prêts à projeter ou distribuer sont regroupés dans `course-materials/`. Les versions Markdown des TP restent séparées dans `tp/` pour lire et copier les commandes. Le laboratoire exécutable reste seul dans `labs/`.

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
- `course-materials/` : présentations et guides TP au format PDF ;
- `tp/`, `td/` : sujets étudiants au format Markdown ;
- `starter-files/` : code à compléter et tests de départ ;
- `labs/shoplab/` : application locale, Compose et scripts de cycle de vie ;
- `scripts/` : setup et vérification hôte ;
- `.github/workflows/student-labs.yml` : contrôles statiques sans attaque réseau.

Contenu pédagogique sous CC BY-NC-SA 4.0 (`LICENSE-CONTENT.md`); code sous MIT (`LICENSE-CODE.md`). Établissement, semestre et charte visuelle : **À confirmer**.
