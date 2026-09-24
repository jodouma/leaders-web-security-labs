# Dépannage

## Lire le statut

`[PASS]` vérifié ici; `[WARN]` utilisable mais validation manuelle requise; `[FAIL]` bloque la suite. Joignez les versions et la ligne de statut, pas des secrets.

| Symptôme | Diagnostic sûr | Action |
| --- | --- | --- |
| daemon inaccessible | `docker info` | démarrer Docker Desktop/Colima/service |
| `docker compose` absent | `docker compose version` | installer plugin v2 selon guide OS |
| port occupé | `lsof -nP -iTCP:8080 -sTCP:LISTEN` ou `ss -ltn` | définir `SHOPLAB_HTTP_PORT=18080` et HTTPS 18443 |
| certificat refusé | `openssl s_client ...` | utiliser `curl -k` uniquement pour ce lab |
| API unhealthy | `labs/shoplab/scripts/compose.sh --profile core logs --tail=80 api db` | lire première erreur, reset si données jetables |
| espace insuffisant | `docker system df` | cleanup du projet; ne pas purger globalement sans autorisation |
| WSL lent/permissions | `pwd` | déplacer sous `~/`, pas `/mnt/c` |
| SCA sans réseau | sortie outil | noter WARN/non évalué, jamais PASS |

Cycle de récupération : `./scripts/cleanup.sh`, vérifier les ports, `./scripts/reset.sh`, `./scripts/health-check.sh core`. `cleanup.sh` ne cible que le nom de projet calculé/`SHOPLAB_PROJECT`; ne lancez pas de suppression Docker globale.
