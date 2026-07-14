# Architecture technique — SokoLink

**Version :** 1.0  
**Date :** 14 juillet 2026  
**Produit :** Marketplace B2B agroalimentaire RDC  
**Clients :** Flutter (iOS / Android ; web admin plus tard)  
**API :** NestJS + Prisma + PostgreSQL  

---

## 1. Vue d’ensemble

```
┌──────────────────┐     HTTPS/JSON      ┌─────────────────────┐
│  SokoLink Mobile │────────────────────▶│  SokoLink API       │
│  (Flutter)       │◀────────────────────│  (NestJS)           │
└──────────────────┘                     │                     │
                                         │  Auth JWT           │
┌──────────────────┐                     │  REST /v1           │
│  Admin (Flutter  │────────────────────▶│  Uploads → S3/local │
│  Web — phase 2)  │                     │  Mail transactional │
└──────────────────┘                     └──────────┬──────────┘
                                                    │
                                         ┌──────────▼──────────┐
                                         │  PostgreSQL         │
                                         │  (Prisma ORM)       │
                                         └─────────────────────┘
```

**Principe :** une API unique ; Flutter est le client principal (mobile-first). Pas de Next.js obligatoire pour le MVP applicatif. Une landing marketing statique pourra être ajoutée séparément pour le SEO.

---

## 2. Décisions stack

| Couche | Choix | Justification |
|--------|--------|----------------|
| Mobile | **Flutter 3.x** | Demande produit ; un codebase iOS+Android ; bon offline partiel plus tard |
| État UI | **Riverpod** | Testable, scalable vs setState |
| Nav | **go_router** | Deep links RFQ / fiches |
| HTTP | **dio** + interceptors JWT | Timeouts 3G, refresh token |
| API | **NestJS 11** | Modules clairs (Auth, Companies, Products, RFQs…) |
| ORM | **Prisma** | Schéma lisible, migrations |
| DB | **PostgreSQL** | Relationnel (RFQ, rôles, plans) |
| Fichiers | Disque local en dev ; **S3-compatible** en prod | Docs RCCM / photos |
| Auth | **OTP téléphone** + **PIN local** (appareil) ; **JWT** long (jusqu’au logout) | Réduit le coût SMS ; session persistante |
| Email | Provider transactionnel (Resend / SMTP) | Reset password, notifs RFQ |

---

## 3. Structure monorepo

```
SokoLink/
├── docs/                 # PRD, CDC, US, architecture
├── api/                  # NestJS
│   ├── prisma/
│   ├── src/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── companies/
│   │   ├── products/
│   │   ├── rfqs/
│   │   ├── messages/
│   │   ├── billing/
│   │   ├── admin/
│   │   └── common/
│   └── uploads/          # dev only
└── mobile/               # Flutter
    └── lib/
        ├── core/         # theme, network, router, constants
        ├── data/         # DTOs, API clients, repositories
        └── features/     # auth, home, catalog, rfq, chat, profile, admin
```

---

## 4. Modèle de données (cœur)

```
User 1───1 Company
User (role platform: USER | ADMIN)
Company ──< CompanyRole (SUPPLIER_MP | PROCESSOR | BUYER)
Company ──< Document (RCCM | NIF | ID, status)
Company ──< Product (type MP | FINISHED)
Company ── subscription (FREE | PRO)
Rfq (issuer Company) ──< RfqInvite / open
Rfq ──< RfqResponse (from Company)
Conversation ──< Message
```

Détail des enums et champs : fichier `api/prisma/schema.prisma`.

---

## 5. API REST (préfixe `/v1`)

| Domaine | Endpoints (indicatifs) |
|---------|------------------------|
| Auth | `POST /auth/register`, `/login`, `/refresh`, `/forgot-password` |
| Me | `GET/PATCH /me`, `GET/PATCH /me/company` |
| Docs | `POST /me/company/documents`, admin validate |
| Products | `CRUD /products`, `GET /products/search` |
| Search | `GET /search?intent=mp\|finished&...` |
| RFQ | `CRUD /rfqs`, `POST /rfqs/:id/responses` |
| Messages | `GET/POST /conversations`, `/conversations/:id/messages` |
| Billing | `POST /billing/pro-request`, admin activate |
| Admin | `/admin/companies`, `/admin/documents`, `/admin/subscriptions` |
| Public | `GET /categories`, `GET /provinces` |

Convention : JSON camelCase côté API ; erreurs `{ "statusCode", "message", "error" }`.

---

## 6. Auth & sécurité

1. Register crée `User` + `Company` + rôles.  
2. Login → `accessToken` (15–60 min) + `refreshToken` (7–30 j).  
3. Guards Nest : `JwtAuthGuard`, `RolesGuard` (`ADMIN`).  
4. Uploads : MIME whitelist, taille max 5 Mo.  
5. Rate-limit login + premier message.  
6. Secrets via `.env` (jamais commités).  

---

## 7. Application Flutter — architecture features

```
features/auth/          login, register
features/home/          intentions MP / finis
features/search/        filtres, résultats
features/company/       fiche publique
features/catalog/       mes produits
features/rfq/           créer, lister, répondre, comparer
features/chat/          threads + WhatsApp launch
features/profile/       docs, upgrade Pro
features/admin/         (si même app avec role ADMIN)
```

**UX mobile-first :** listes, bottom nav (Accueil / Recherche / RFQ / Messages / Profil).

---

## 8. Environnements

| Env | API | DB |
|-----|-----|-----|
| local | `http://localhost:3100/v1` | Postgres Docker (`docker compose up -d`, port **5434**) |
| staging | HTTPS | Managed Postgres |
| prod | HTTPS | Managed Postgres + S3 + backups |

Flutter : `--dart-define=API_BASE_URL=...`

---

## 9. Hors architecture MVP

- Escrow / paiements en ligne transactionnels  
- WebSocket chat temps réel obligatoire (polling ou refresh manuel ok en MVP)  
- Multi-tenant multi-pays  
- Microservices  

---

## 10. Ordre d’implémentation

1. Schéma Prisma + Auth + Company  
2. Flutter auth + shell navigation  
3. Catalogue + search  
4. RFQ  
5. Messages + WhatsApp  
6. Billing Free/Pro + Admin  

Aligné sur les sprints de `docs/user-stories.md`.  
