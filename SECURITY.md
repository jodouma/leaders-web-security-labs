# Politique de sécurité des laboratoires

## Périmètre autorisé

Seulement `127.0.0.1`, `localhost`, les services du réseau Docker ShopLab et une plateforme expressément autorisée par l'enseignant. Les domaines `.invalid` sont documentaires et ne sont jamais contactés. Les comptes/données sont synthétiques.

## Stop conditions

Arrêtez immédiatement si une cible résout hors du lab, si un secret réel apparaît, si une commande propose un shell sur une donnée contrôlée, ou si un test risque d'affecter un autre projet Docker. Exécutez `labs/shoplab/scripts/cleanup.sh`, conservez seulement une preuve expurgée et signalez l'écart.

## Preuves

Ne remettez jamais token, cookie, password, clé privée, variable d'environnement complète ou donnée personnelle. Remplacez la valeur par `[EXPURGÉ]`; conservez timestamp UTC, statut, chemin local et correlation ID. Les identifiants du README sont uniquement des valeurs synthétiques de formation.

## Signaler un problème dans ce dépôt

Utilisez le canal privé indiqué par l'établissement (**À confirmer**) pour une fuite ou une vulnérabilité non intentionnelle. N'ouvrez pas d'issue publique contenant une preuve sensible. Les vulnérabilités intentionnelles de ShopLab ne doivent jamais être exposées au réseau.
