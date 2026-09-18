# TD04 — Cellule d'incident et rapport de clôture

**Séance S14 · 90 min · C01, C12 · Simulation sur données synthétiques**

## Déclencheur

À 09:14 UTC, ShopLab produit une hausse de `403` et cinq échecs login. À 09:16, un `200` sur `/api/users/2` apparaît depuis une session Alice dans le mode vulnérable. À 09:18, le service est passé en corrected. Un collègue affirme que « le proxy a bloqué l'attaque ».

```json
{"timestamp":"09:14:02Z","event":"authentication","result":"failed","username":"alice","correlation_id":"inc-01"}
{"timestamp":"09:16:11Z","event":"authorization","result":"allowed","subject_id":"1","object_id":2,"correlation_id":"inc-07","mode":"vulnerable"}
{"timestamp":"09:18:30Z","event":"http_request","result":"denied","status":403,"correlation_id":"inc-09","mode":"corrected"}
```

## Mission par injects

1. **Triage, 15 min :** faits/hypothèses/inconnues, sévérité provisoire, scope, stop conditions.
2. **Inject A, 15 min :** on vous demande le token complet « pour enquêter ». Refusez et proposez une preuve expurgée équivalente.
3. **Chronologie, 15 min :** construisez une ligne UTC avec source et niveau de confiance. Dites ce que les extraits ne prouvent pas.
4. **Confinement, 15 min :** choisissez trois actions réversibles et ordonnées; distinguez mode corrected, révocation de session et correction source.
5. **Validation, 15 min :** planifiez retests 200/401/403, recherche de logs, non-régression et cleanup. Définissez le critère de retour au service.
6. **Communication, 15 min :** résumé dirigeant (100 mots) et annexe technique (preuves, cause, correction, limites, actions).

## Règles

Aucune preuve ne contient token/cookie/password. Ne déclarez pas une compromission externe ni une attribution. Les lignes sont synthétiques. Un mode corrigé n'est pas à lui seul une analyse de cause ni une preuve de déploiement production.

## Barème /20

| Axe | Insuffisant | Conforme | Maîtrisé | Pts |
| --- | --- | --- | --- | ---: |
| Triage | conclusions hâtives | faits/hypothèses séparés | confiance et sévérité révisables | 5 |
| Preuve | secret copié | expurgation/chaîne | preuve minimale reproductible | 4 |
| Réponse/retest | action unique | confinement/correction/retest | rollback et critères | 6 |
| Communication | jargon/attribution | deux audiences | limites et décisions claires | 5 |
