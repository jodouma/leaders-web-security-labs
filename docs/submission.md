# Remise étudiante

Depuis `labs/shoplab`, créez le dossier `preuves/TPxx/`, ignoré par Git. Pour la remise, copiez seulement les éléments expurgés dans un dossier hors du dépôt : rapport Markdown/PDF, index des preuves, extraits minimaux, tests écrits et sortie finale PASS/WARN/FAIL. Pour chaque preuve : timestamp UTC, commande locale, résultat, interprétation et limite.

Avant remise :

- remplacer token/cookie/password/clé par `[EXPURGÉ]` ;
- supprimer `.env`, archives DB, `.state`, logs complets et captures contenant d'autres projets ;
- vérifier que toutes les cibles sont localhost/ShopLab ;
- exécuter reset, vérification puis cleanup et joindre l'état final ;
- indiquer OS/architecture, versions Docker/Compose et commit du support.

N'envoyez pas le dossier `.git`, des images Docker, une clé TLS ou une copie de base. Le canal et le nommage institutionnels sont **À confirmer**.
