# Installation macOS

Chemin recommandé : Homebrew + Colima + Docker CLI/Compose. Docker Desktop reste compatible si déjà géré par l'organisation.

```bash
./scripts/setup-macos.sh --install
./scripts/verify-host.sh
```

Le setup installe seulement les éléments absents, crée les liens de plugins CLI si nécessaires et démarre Colima avec 2 CPU, 4 Gio, 20 Gio. Il est relançable. Sur Apple Silicon, les images utilisées sont multi-architecture; un `[WARN]` signale une image non encore validée localement.

Pour arrêter la VM après cleanup : `colima stop`. La suppression complète `colima delete` détruit sa VM et n'est jamais exécutée par ces scripts. Le certificat ShopLab reste local et auto-signé; ne l'ajoutez pas au trousseau système.
