# Sécurité des applications et services web — espace étudiant

14 séances de 3 h (42 h). Toutes les expériences restent sur `127.0.0.1` ou dans le réseau Docker isolé de ShopLab.

## Commencer ici

1. **Cours** — [cours complet](course-materials/course/cours_complet.pdf)
2. **Travaux dirigés** — [TD01](course-materials/td-guides/TD01_autopsie_requete.pdf), [TD02](course-materials/td-guides/TD02_modele_menace_checkout.pdf), [TD03](course-materials/td-guides/TD03_revue_architecture_api.pdf), [TD04](course-materials/td-guides/TD04_cellule_incident.pdf)
3. **Travaux pratiques** — [TP01](course-materials/tp-guides/TP01_observer_le_flux.pdf), [TP02](course-materials/tp-guides/TP02_session_cookie_csrf.pdf), [TP03](course-materials/tp-guides/TP03_autorisation_bola.pdf), [TP04](course-materials/tp-guides/TP04_injections_xss_csrf.pdf), [TP05](course-materials/tp-guides/TP05_fichiers_upload_ssrf_commande.pdf), [TP06](course-materials/tp-guides/TP06_api_proxy_conteneurs.pdf), [TP07](course-materials/tp-guides/TP07_base_devsecops_observabilite.pdf)

## Parcours des 14 séances

| Séance | Sujet | Cours | TD/TP | Résultat attendu |
| --- | --- | --- | --- | --- |
| Séance 01 | Éthique, périmètre et preuve | [S01, p. 9](course-materials/course/cours_complet.pdf#page=9) | [TP01-A](course-materials/tp-guides/TP01_observer_le_flux.pdf) | Hôte validé, trace locale et index de preuves |
| Séance 02 | Chemin complet d’une requête | [S02, p. 14](course-materials/course/cours_complet.pdf#page=14) | [TP01-B/D](course-materials/tp-guides/TP01_observer_le_flux.pdf) + [TD01](course-materials/td-guides/TD01_autopsie_requete.pdf) | Flux DNS→DB annoté et hypothèse falsifiable |
| Séance 03 | HTTP, cookies et navigateur | [S03, p. 19](course-materials/course/cours_complet.pdf#page=19) | [TP02-A](course-materials/tp-guides/TP02_session_cookie_csrf.pdf) | Transaction annotée et matrice navigateur/serveur |
| Séance 04 | Actifs, frontières et menaces | [S04, p. 24](course-materials/course/cours_complet.pdf#page=24) | [TD02](course-materials/td-guides/TD02_modele_menace_checkout.pdf) | DFD lisible et registre de menaces |
| Séance 05 | Authentification et session | [S05, p. 29](course-materials/course/cours_complet.pdf#page=29) | [TP02-B/D](course-materials/tp-guides/TP02_session_cookie_csrf.pdf) | Rotation, logout et CSRF prouvés |
| Séance 06 | Autorisation et BOLA | [S06, p. 34](course-materials/course/cours_complet.pdf#page=34) | [TP03](course-materials/tp-guides/TP03_autorisation_bola.pdf) | Matrice 200/401/403 et contrôle objet |
| Séance 07 | Validation et injection SQL | [S07, p. 38](course-materials/course/cours_complet.pdf#page=38) | [TP04-A](course-materials/tp-guides/TP04_injections_xss_csrf.pdf) | SQLi avant/après et recherche légitime |
| Séance 08 | XSS, CSRF et CSP | [S08, p. 42](course-materials/course/cours_complet.pdf#page=42) | [TP04-B/C](course-materials/tp-guides/TP04_injections_xss_csrf.pdf) | Encodage, refus CSRF, CSP et quiz |
| Séance 09 | Fichiers, commandes et SSRF | [S09, p. 46](course-materials/course/cours_complet.pdf#page=46) | [TP05](course-materials/tp-guides/TP05_fichiers_upload_ssrf_commande.pdf) | Allowlists et retests locaux bornés |
| Séance 10 | Sécurité des API | [S10, p. 50](course-materials/course/cours_complet.pdf#page=50) | [TD03](course-materials/td-guides/TD03_revue_architecture_api.pdf) + [TP06-A](course-materials/tp-guides/TP06_api_proxy_conteneurs.pdf) | Inventaire, mass assignment filtré et vrai 429 |
| Séance 11 | Proxy, TLS et conteneurs | [S11, p. 54](course-materials/course/cours_complet.pdf#page=54) | [TP06-B](course-materials/tp-guides/TP06_api_proxy_conteneurs.pdf) | Headers, certificat et isolation vérifiés |
| Séance 12 | PostgreSQL et moindre privilège | [S12, p. 58](course-materials/course/cours_complet.pdf#page=58) | [TP07-A](course-materials/tp-guides/TP07_base_devsecops_observabilite.pdf) | Rôles minimaux, refus et restauration |
| Séance 13 | DevSecOps et livraison | [S13, p. 62](course-materials/course/cours_complet.pdf#page=62) | [TP07-B](course-materials/tp-guides/TP07_base_devsecops_observabilite.pdf) | Rapport de gate, triage et checkpoint |
| Séance 14 | Incident, remédiation et rapport | [S14, p. 66](course-materials/course/cours_complet.pdf#page=66) | [TD04](course-materials/td-guides/TD04_cellule_incident.pdf) | Chronologie, remédiation, retest et rapport |

## Préparer l’environnement

Prérequis : Git, Docker avec Compose v2, `curl`, OpenSSL, Python 3.11+, 2 CPU, 4 Gio de RAM et 12 Gio libres.

```bash
git clone https://github.com/jodouma/leaders-web-security-labs.git
cd leaders-web-security-labs
./scripts/verify-host.sh
cd labs/shoplab
./scripts/lab-start.sh core
./scripts/reset.sh       # revenir à l’état initial
./scripts/cleanup.sh     # fin de séance
```

Guide OS : [Windows 11 + WSL2](docs/setup/windows-wsl2.md) · [Ubuntu](docs/setup/ubuntu.md) · [Kali Linux](docs/setup/kali.md) · [macOS](docs/setup/macos.md). Sous PowerShell natif, utilisez `.\scripts\Verify-Host.ps1`.

## Infrastructure de support

Le code ShopLab, Docker Compose, les scripts, les starters, le dépannage et la remise restent disponibles dans `labs/`, `scripts/`, `starter-files/` et `docs/`. Ils servent les TP; ce ne sont pas des supports de cours concurrents.

Règles : [sécurité](SECURITY.md) · [remise](docs/submission.md) · [dépannage](docs/troubleshooting.md). Contenu pédagogique sous CC BY-NC-SA 4.0; code sous MIT.
