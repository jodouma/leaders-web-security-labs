# Maintenance IA — dépôt étudiant

Fichier de support pour Codex, Claude et les mainteneurs. Il n’est pas un support étudiant.

## Priorités

1. Lire `AGENTS.md`, `README.md` et le dernier état Git.
2. Préserver les 14 séances, les identifiants S01–S14, TD01–TD04 et TP01–TP07.
3. Garder le README limité aux trois catégories Cours, Travaux dirigés et Travaux pratiques.
4. Ne jamais ajouter de corrigé, réponse réservée, note enseignant, secret ou chemin privé.

## Classification

| Catégorie | Emplacement |
| --- | --- |
| Canonique étudiant | `course-materials/course/cours_complet.pdf`, quatre PDF TD, sept PDF TP |
| Source nécessaire | `td/`, `tp/`, `docs/` |
| Runtime nécessaire | `labs/shoplab/`, `scripts/`, `starter-files/` |
| Support build/QA | `.github/`, ce fichier et `scripts/check-navigation.py` |
| Temporaire | `labs/shoplab/.state/`, `preuves/`, caches, locks |

## Contrôles à faible coût

```bash
python3 scripts/check-navigation.py
find scripts labs -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
python3 -m compileall -q labs/shoplab/app starter-files
docker compose -f labs/shoplab/docker-compose.yml --profile core config -q
```

Utiliser `rg` avant d’ouvrir des fichiers entiers. Réutiliser les scripts ShopLab; ne pas recopier leurs commandes dans de nouveaux guides. Ne reconstruire et rendre que les PDF dont la source change. Pour une validation runtime, cibler `127.0.0.1`, nettoyer avec `labs/shoplab/scripts/cleanup.sh` et confirmer zéro conteneur restant.

