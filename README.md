# SokoLink

Marketplace B2B agroalimentaire en RDC — connecte fournisseurs de matières premières, transformateurs et acheteurs professionnels.

## Stack

| Couche | Techno | Dossier |
|--------|--------|---------|
| Mobile | Flutter | `mobile/` |
| API | NestJS + Prisma + PostgreSQL | `api/` |
| Admin web | NestJS + Handlebars | `admin/` |
| Infra | Docker Compose | `docker-compose.yml` |
| CI/CD | GitHub Actions | `.github/workflows/ci-cd.yml` |

## Démarrage local (Docker)

```bash
docker compose up -d --build
```

- API : http://localhost:3100/v1/health  
- Admin : http://localhost:3200  
- Postgres : localhost:5434  

Compte admin (après seed) : `admin@sokolink.cd` / `AdminSokoLink!2026`

### Seed

```bash
docker compose exec api npx prisma db seed
```

## Démarrage dev

```bash
docker compose up -d db
cd api && cp .env.example .env && npm ci && npx prisma migrate dev && npm run prisma:seed && npm run start:dev
cd admin && npm ci && npm run start:dev
cd mobile && flutter pub get && flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3100/v1
```

## CI/CD

Sur chaque push/PR :
1. Qualité API (build, unit, regression e2e, npm audit)
2. Qualité Admin + Flutter analyze/tests
3. Scan sécurité Dockerfiles (Trivy)
4. Smoke Docker Compose

Sur `main` si tout passe :
- Build & push images `ghcr.io/<owner>/sokolink-api` et `sokolink-admin`
- Smoke production optionnel (`vars.PRODUCTION_API_URL`)
- Webhook deploy optionnel (`secrets.DEPLOY_WEBHOOK_URL`)

## Documentation produit

- [PRD](docs/PRD.md)
- [Cahier des charges](docs/cahier-des-charges.md)
- [User stories](docs/user-stories.md)
- [Architecture](docs/ARCHITECTURE.md)
