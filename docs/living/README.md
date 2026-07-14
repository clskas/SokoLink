# Documentation vivante — règle d’équipe

## Définition

Une documentation est **vivante** si elle :

1. reste versionnée avec le code (`docs/`) ;
2. est exposée aux utilisateurs (app `/legal/*`, admin liens) ;
3. est contractuelle côté API (`docs/api/openapi.yaml`) ;
4. reçoit une entrée `CHANGELOG.md` à chaque livraison notable.

## Checklist PR

- [ ] Manuel à jour si parcours utilisateur modifié
- [ ] CGU / confidentialité si règles métier ou données changent
- [ ] OpenAPI si endpoint ajouté/modifié
- [ ] Changelog renseigné
- [ ] CDC / user stories si scope MVP évolue

## Automatisation

- API `GET /v1/legal/{cgu|confidentialite|manuel}` lit les fichiers Markdown du dossier `docs/`
- Docker image API embarque `docs/` pour prod
- MkDocs optionnel : `cd docs && mkdocs serve`
