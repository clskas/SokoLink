# Cahier des charges — SokoLink (MVP)

**Version :** 1.0  
**Date :** 14 juillet 2026  
**Référence PRD :** `docs/PRD.md`  
**Périmètre :** Marketplace B2B agroalimentaire RDC — Directory + RFQ + Messagerie + Freemium  

---

## 1. Objet du document

Définir les exigences fonctionnelles (EF), non fonctionnelles (ENF) et les contraintes d’implémentation du MVP SokoLink, afin de préparer le développement et les tests d’acceptation.

---

## 2. Acteurs du système

| Acteur | Description |
|--------|-------------|
| Visiteur | Non authentifié : consultation limitée éventuelle des pages publiques |
| Utilisateur entreprise | Compte lié à une organisation ; peut cumuler rôles |
| Fournisseur MP | Vend / propose des matières premières |
| Transformateur | Achète MP et/ou vend produits finis |
| Acheteur B2B | Cherche produits finis |
| Admin | Back-office plateforme |

---

## 3. Modules fonctionnels

### M1 — Authentification & comptes

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-1.1 | Inscription email + mot de passe (ou téléphone OTP si retenu) | Must |
| EF-1.2 | Création d’une **entreprise** (raison sociale, province, ville, contacts) | Must |
| EF-1.3 | Sélection de un ou plusieurs rôles : fournisseur MP, transformateur, acheteur | Must |
| EF-1.4 | Connexion / déconnexion / reset mot de passe | Must |
| EF-1.5 | Un utilisateur peut appartenir à une seule entreprise en MVP | Should |
| EF-1.6 | Session sécurisée (JWT ou cookies httpOnly) | Must |

### M2 — Profil entreprise & confiance documentaire

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-2.1 | Édition du profil (description, logo, zones de livraison / zones d’achat, capacités) | Must |
| EF-2.2 | Upload documents : RCCM, NIF, pièce d’identité gérant (PDF/JPG, taille max définie) | Must |
| EF-2.3 | Statuts docs : `non_soumis` / `en_review` / `accepté` / `rejeté` (+ motif) | Must |
| EF-2.4 | Badge visible : « Docs en revue » / « Docs validés » (pas d’audit terrain) | Must |
| EF-2.5 | Affichage province + contacts (email, téléphone, WhatsApp) | Must |

### M3 — Catalogue produits

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-3.1 | Créer / éditer / archiver un produit | Must |
| EF-3.2 | Attributs : nom, type (`MP` \| `fini`), catégorie, description, unité, prix indicatif (optionnel), MOQ, capacité / mois, province d’origine, photos | Must |
| EF-3.3 | Taxonomie agro MVP (liste initiale ci-dessous) | Must |
| EF-3.4 | Limite du nombre de produits actifs selon plan Free / Pro | Must |
| EF-3.5 | Produits visibles selon statut entreprise (ex. masqués si compte suspendu) | Should |

**Taxonomie initiale (extensible) :**

- Céréales & farines  
- Tubercules & dérivés (manioc…)  
- Huiles & oléagineux  
- Sucre & édulcorants  
- Café, cacao, thé  
- Protéines (viande, poisson, volaille)  
- Fruits, légumes & transformés  
- Boissons  
- Produits laitiers  
- Emballages alimentaires  
- Autres agro  

Chaque produit est tagué **MP** ou **produit fini**.

### M4 — Recherche & découverte

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-4.1 | Sélecteur d’intention : `Chercher MP` / `Chercher produits finis` | Must |
| EF-4.2 | Recherche plein texte + filtres : catégorie, province, type, capacité, badge docs | Must |
| EF-4.3 | Pages résultats : liste entreprises et/ou produits | Must |
| EF-4.4 | Tri : pertinence, date, featured Pro en priorité contrôlée | Must |
| EF-4.5 | Fiche entreprise + liste produits + CTA Contact / RFQ | Must |

### M5 — RFQ (Request for Quotation)

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-5.1 | Créer une RFQ : titre, type (MP/fini), catégorie, quantité, unité, budget indicatif (opt.), provinces ciblées, délai de réponse, cahier (texte + pièces jointes) | Must |
| EF-5.2 | RFQ ouverte (tous les fournisseurs éligibles) ou ciblée (entreprises sélectionnées) | Must |
| EF-5.3 | Fournisseurs notifiés (email + in-app) ; Pro reçoivent priorité d’affichage | Must |
| EF-5.4 | Réponse RFQ : prix, délai, commentaires, pièce jointe | Must |
| EF-5.5 | L’émetteur compare les réponses (tableau simple) | Must |
| EF-5.6 | Statuts RFQ : `brouillon`, `publiée`, `clôturée`, `annulée` | Must |
| EF-5.7 | Limites Free : nb RFQ / mois et nb réponses / mois | Must |
| EF-5.8 | Marquer un échange lié : `en discussion` / `conclu` / `sans suite` (déclaratif) | Should |

### M6 — Messagerie & contact

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-6.1 | Thread de messagerie entre deux entreprises (lié produit ou RFQ si possible) | Must |
| EF-6.2 | Bouton « Continuer sur WhatsApp » (deep-link wa.me) | Must |
| EF-6.3 | Rate-limit des premiers messages (anti-spam) | Should |
| EF-6.4 | Notifications email des nouveaux messages | Should |

### M7 — Freemium & abonnements

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-7.1 | Plans : Free et Pro (mensuel / annuel) | Must |
| EF-7.2 | Paramètres configurables admin : max produits, max RFQ, max réponses, featured oui/non | Must |
| EF-7.3 | Parcours demande d’abonnement (formulaire) + preuve de paiement upload (MVP) | Must |
| EF-7.4 | Admin active / désactive le plan Pro | Must |
| EF-7.5 | Badge « Pro » + placement featured | Must |
| EF-7.6 | Intégration paiement automatique Mobile Money | Could (post-MVP ok) |

### M8 — Back-office admin

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-8.1 | Liste entreprises, filtres par statut docs / plan | Must |
| EF-8.2 | Validation / rejet documents | Must |
| EF-8.3 | Suspension compte / produit | Must |
| EF-8.4 | Activation abonnements | Must |
| EF-8.5 | Vue RFQ (modération abus) | Should |
| EF-8.6 | Stats basiques : nb comptes, produits, RFQ, réponses | Should |

### M9 — Contenu & légal

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-9.1 | Pages : Accueil, Comment ça marche, Tarifs, CGU, Confidentialité, Contact | Must |
| EF-9.2 | Disclaimer : SokoLink n’est pas partie aux contrats commerciaux MVP | Must |

---

## 4. Exigences non fonctionnelles

| ID | Exigence |
|----|----------|
| ENF-1 | UI **mobile-first**, breakpoints desktop |
| ENF-2 | Langue MVP : **français** |
| ENF-3 | Temps de chargement perçu acceptable sur 3G (lazy images, pages légères) |
| ENF-4 | Uploads : types MIME restrictifs, taille max (ex. 5 Mo / fichier) |
| ENF-5 | Mots de passe hashés ; secrets hors code ; HTTPS en prod |
| ENF-6 | Sauvegardes DB quotidiennes en prod |
| ENF-7 | Journalisation erreurs applicatives |
| ENF-8 | Accessibilité de base (contrastes, labels formulaires) |
| ENF-9 | Données hébergées chez un fournisseur avec disponibilité RDC/Afrique ou latence acceptable |

---

## 5. Contraintes & hypothèses techniques (recommandations)

Non contractuelles tant que non validées en architecture détaillée ; recommandation initiale :

| Domaine | Proposition MVP |
|---------|-----------------|
| Mobile | **Flutter** (iOS + Android) |
| Backend API | NestJS + Prisma |
| DB | PostgreSQL |
| Auth | JWT (access + refresh) |
| Stockage fichiers | S3-compatible (local en dev) |
| Email | Transactional (Resend, Postmark…) |
| Déploiement API | Render / Railway / VPS |

Le choix stack exact sera figé en phase d’architecture avant l’implémentation.

---

## 6. Règles métier notables

1. Une entreprise peut publier à la fois des produits **MP** et **finis**.  
2. Les acheteurs purs ne sont pas facturés.  
3. Sans documents en statut `accepté`, le badge « Docs validés » n’apparaît pas ; la publication produit peut rester autorisée (paramétrable) pour ne pas bloquer la liquidité.  
4. Les prix affichés sont **indicatifs** ; le deal final est hors plateforme.  
5. L’admin peut retirer un contenu signalé (fraude, contrefaçon docs).  

---

## 7. Volumétrie estimée MVP (dimensionnement)

| Ressource | Ordre de grandeur an 1 |
|-----------|------------------------|
| Entreprises | 200 → 2 000 |
| Produits | 500 → 10 000 |
| RFQ / mois | 50 → 500 |
| Fichiers stockés | < 50 Go |

---

## 8. Livrables attendus (implémentation)

1. Application web MVP conforme EF Must  
2. Back-office admin  
3. Documentation technique README (setup)  
4. Jeu de données seed catégories + comptes démo  
5. Checklist de tests d’acceptation alignée user stories  

---

## 9. Critères d’acceptation globaux

- Couverture de 100 % des EF **Must**  
- Parcours A/B/C du PRD réalisables sur mobile  
- Aucune fuite de documents privés hors droits  
- Plans Free/Pro respectés dans l’UI et l’API  

---

## 10. Documents liés

- [`PRD.md`](./PRD.md)  
- [`user-stories.md`](./user-stories.md)  
