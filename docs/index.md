# Documentation SokoLink (vivante)

Cette documentation est la **source de vérité** produit / usage / juridique.  
Elle évolue avec le code : toute feature MVP doit mettre à jour les pages concernées.

## Index

| Document | Rôle |
|----------|------|
| [PRD](./PRD.md) | Vision, scope, KPI |
| [Cahier des charges](./cahier-des-charges.md) | Exigences fonctionnelles |
| [User stories](./user-stories.md) | Stories + critères d’acceptation |
| [Architecture](./ARCHITECTURE.md) | Stack technique |
| [Manuel utilisateur](./manuel-utilisateur.md) | Guide terrain |
| [CGU](./legal/cgu.md) | Conditions d’utilisation |
| [Confidentialité](./legal/confidentialite.md) | Données personnelles |
| [API OpenAPI](./api/openapi.yaml) | Contrat API vivant |
| [Changelog](./CHANGELOG.md) | Historique des versions doc/code |
| [Règles doc vivante](./living/README.md) | Processus d’équipe |

## Règle « documentation vivante »

1. **Une story terminée = doc à jour** (manuel et/ou OpenAPI et/ou CDC).
2. Les endpoints exposés dans l’app doivent figurer dans `docs/api/openapi.yaml`.
3. Les CGU / confidentialité sont servies via l’API `GET /v1/legal/*` et affichées dans l’app.
4. Le pipeline CI peut échouer si OpenAPI est présent mais non valide (à renforcer progressivement).
5. Le fichier `docs/CHANGELOG.md` reçoit une entrée à chaque livraison notable.

## Consommation

- **Humains** : lecture GitHub / dossier `docs/`
- **App mobile** : écrans Aide / Légal (API legal)
- **Admin** : lien documentation dans le dashboard
- **Développeurs** : OpenAPI + Architecture
