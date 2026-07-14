# Changelog — SokoLink

## 2026-07-14 — Rôles / sécurité

### Ajouté
- Interfaces adaptées au rôle (acheteur / fournisseur MP / transformateur)
- Guards API (`CompanyRoles`, compte actif) + throttle OTP
- Refresh JWT, verrouillage PIN après 5 échecs
- Catalogue / RFQ créés selon capacités du compte

## 2026-07-14 — Auth OTP + PIN + offline

### Ajouté
- Connexion mobile par **OTP téléphone** (`POST /v1/auth/otp/request|verify`)
- **PIN local** après première connexion (ouvreures suivantes sans SMS)
- Session JWT longue jusqu’à **déconnexion** explicite
- Mode **hors-ligne** : cache recherche / catalogue / RFQ + file d’attente RFQ

### Docs
- Manuel, CGU, OpenAPI et architecture mis à jour (OTP / PIN)

## 2026-07-14 — MVP catalogue / recherche / docs vivantes

### Ajouté
- Catalogue vendeur enrichi (type, catégorie, unité, province, prix)
- Recherche avec mapping prix / catégorie / badges docs & Pro
- CGU, confidentialité, manuel utilisateur
- Endpoints `GET /v1/legal/{cgu|confidentialite|manuel}`
- OpenAPI vivant + index documentation
- Écrans Aide / Légal dans l’app Flutter

### Technique
- Admin NestJS, Docker, CI/CD déjà en place
