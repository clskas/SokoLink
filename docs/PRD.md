# PRD — SokoLink

**Version :** 1.0  
**Date :** 14 juillet 2026  
**Statut :** Validé pour cadrage MVP  
**Produit :** Marketplace B2B agroalimentaire — RDC  

---

## 1. Vision

SokoLink est la plateforme numérique qui met en relation, en toute confiance, les acteurs de la filière agroalimentaire en République démocratique du Congo :

- **Upstream :** fournisseurs de matières premières ↔ fabricants / transformateurs  
- **Downstream :** producteurs de produits finis ↔ acheteurs professionnels (grossistes, Horeca, institutions, distribution B2B)

**Promesse :** découvrir, qualifier et contacter des partenaires industriels locaux — via annuaire, RFQ et messagerie — sans imposer de paiement en ligne au lancement.

---

## 2. Problème

Aujourd’hui, le sourcing B2B agro en RDC repose sur WhatsApp, le bouche-à-oreille et les intermédiaires informels. Conséquences :

- Opacité des prix et des capacités  
- Difficulté à trouver des fournisseurs hors de sa province  
- Faible traçabilité des entreprises (RCCM, NIF)  
- Peu d’outils pour comparer plusieurs devis (RFQ)  
- Les marketplaces mondiales (Made-in-China, Alibaba) couvrent mal le tissu local congolais

---

## 3. Décisions produit figées

| # | Sujet | Décision |
|---|--------|----------|
| 1 | Secteur | Agroalimentaire / filière agro-industrielle B2B |
| 2 | Loops | Upstream + Downstream dès le MVP |
| 3 | Géographie | Toute la RDC |
| 4 | Confiance | Documents auto-déclarés (contrôle admin léger) |
| 5 | Rôle | Directory + RFQ + messagerie (pas d’escrow MVP) |
| 6 | Monétisation | Freemium fournisseurs ; acheteurs gratuits |

---

## 4. Objectifs produit (MVP — 3 à 6 mois)

| Objectif | Indicateur de succès (cible indicative) |
|----------|----------------------------------------|
| Constituer une offre utile | ≥ 200 fiches entreprises actives (dont ≥ 80 fournisseurs) |
| Générer de la demande | ≥ 100 RFQ publiées |
| Engager les deux sides | ≥ 40 % des RFQ avec ≥ 1 réponse sous 72 h |
| Monétiser tôt | ≥ 15 abonnements Pro payants (ou équivalent) |
| Couverture nationale | Entreprises présentes dans ≥ 8 provinces |

*Les cibles chiffrées sont des hypothèses à ajuster après 10–15 interviews terrain.*

---

## 5. Personas

### P1 — Fournisseur de matières premières
Coopérative, courtier, agrégateur ou PME agricole. Cherche des transformateurs et acheteurs volume. Paiera pour être visible hors de sa province.

### P2 — Transformateur / fabricant
Usine ou atelier (farine, huile, boisson, conserve…). A souvent un **double rôle** : achète des MP et revend des finis. Persona cœur du produit.

### P3 — Acheteur B2B produits finis
Grossiste, hôtel/restaurant volume, cantine, chaîne de distribution. Veut comparer, obtenir des devis, filtrer par province et capacité.

### P4 — Admin SokoLink
Opère le back-office : validation docs, modération, support, activation des plans Pro.

---

## 6. Périmètre MVP (In scope)

1. Inscription / connexion entreprise (rôles : fournisseur MP, transformateur, acheteur, multi-rôles)  
2. Profil entreprise + upload documents (RCCM, NIF, pièce d’identité du gérant)  
3. Catalogue produits (MP et/ou finis) avec catégories agro  
4. Recherche & filtres (province, catégorie, type de loop, capacité, mot-clé)  
5. Intention UX duale : « Je cherche des MP » / « Je cherche des finis (ou des clients) »  
6. RFQ : création, diffusion ciblée ou ouverte, réponses, comparaison simple  
7. Messagerie interne + deep-link WhatsApp  
8. Plans Free / Pro fournisseurs (limites catalogue, featured, priorité RFQ, badge)  
9. Back-office admin (validation docs, modération, gestion abonnements manuelle ou semi-auto)  
10. Expérience **mobile-first** (web responsive / PWA)

---

## 7. Hors scope MVP (Out of scope)

- Escrow / paiement en ligne / commission sur transaction  
- Logistique / tracking transporteurs  
- Audits terrain type SGS / visite usine obligatoire  
- Application native iOS/Android dédiée (phase ultérieure)  
- Multi-pays / multi-devises avancées  
- Finance (précommande, crédit fournisseur)  
- B2C / livraison consommateur final  

---

## 8. Parcours clés (happy paths)

### A. Transformateur cherche du maïs (upstream)
1. Sélectionne l’intention « Matières premières »  
2. Filtre province / catégorie  
3. Consulte fiches + ouvre une RFQ  
4. Reçoit des réponses, contacte via messagerie / WhatsApp  
5. (Optionnel) marque la discussion « conclu »

### B. Grossiste cherche de l’huile embouteillée (downstream)
1. Intention « Produits finis »  
2. Recherche & filtres  
3. Contact direct ou RFQ multi-fournisseurs  

### C. Fournisseur Pro capture de la demande
1. Complète profil + docs + catalogue  
2. Passe en Pro  
3. Apparaît en featured / reçoit RFQ prioritaires  
4. Répond et convertit hors plateforme  

---

## 9. Exigences non fonctionnelles (synthèse)

- Disponible en **français** (MVP)  
- Mobile-first, usable sur réseaux 3G  
- RGPD-like / protection des données personnelles (minimisation, consentement)  
- Disponibilité cible MVP : best-effort (pas de SLA entreprise strict)  
- Séparation claire comptes entreprise / admin  

Détail : voir `cahier-des-charges.md`.

---

## 10. Modèle économique (MVP)

| Offre | Cible | Contenu |
|-------|--------|---------|
| Free | Tous | Recherche, RFQ (limites raisonnables), catalogue restreint pour fournisseurs |
| Pro | Fournisseurs / transformateurs vendeurs | Plus de produits, featured, priorité RFQ, badge « Docs soumis / vérifiés admin » |
| Acheteur | — | Toujours gratuit |

Paiement abonnement : Mobile Money / virement + activation manuelle admin en V1 si besoin.

---

## 11. Roadmap indicative

| Phase | Contenu |
|-------|---------|
| **MVP** | Directory + RFQ + messagerie + freemium + docs auto-déclarés |
| **V1.1** | Amélioration matching RFQ, analytics vendeur, plus de catégories |
| **V2** | Vérification terrain / partenaires locaux, reputation score |
| **V3** | Escrow / trading sécurisé, commission optionnelle |
| **V4** | Expansion Afrique centrale / multi-secteurs |

---

## 12. Risques & mitigations

| Risque | Mitigation |
|--------|------------|
| Marketplace vide | Recrutement manuel des 50–100 premiers fournisseurs ; RFQ « inverse » (l’équipe publie des besoins) |
| Double loop dilué | Taxonomie unique agro + 2 intentions UX ; une seule acquisition marketing |
| Transactions hors plateforme | Accepté en MVP ; monétiser la découverte, pas la transaction |
| Fausses entreprises | Checklist docs + validation admin ; rate-limit des contacts |
| Couverture nationale irréaliste | Lancer ops sur 3–4 hubs (Kinshasa, Lubumbashi, Goma, Kisangani) tout en autorisant l’inscription nationale |

---

## 13. Hypothèses à invalider / valider

1. Les transformateurs cumulent bien les deux intentions dans un même compte.  
2. Les fournisseurs paieront un abo Pro pour de la visibilité locale.  
3. Les RFQ génèrent des réponses utiles sans escrow.  
4. Les docs auto-déclarés suffisent à créer un minimum de confiance.  

---

## 14. Critères de « MVP done »

- Un utilisateur non technique peut s’inscrire, publier un produit, créer une RFQ et recevoir une réponse sur mobile.  
- Un admin peut valider des docs et activer un plan Pro.  
- Les deux intentions (MP / finis) sont utilisables avec des catégories réelles.  
- Les limites Free vs Pro sont appliquées.  

---

## 15. Documents liés

- [`cahier-des-charges.md`](./cahier-des-charges.md) — exigences fonctionnelles & techniques détaillées  
- [`user-stories.md`](./user-stories.md) — epics, user stories, critères d’acceptation  
