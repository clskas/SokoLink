# User stories — SokoLink (MVP)

**Version :** 1.0  
**Date :** 14 juillet 2026  
**Format :** As a… I want… So that… + critères d’acceptation  
**Priorité :** Must / Should / Could  

---

## Epics

| Epic | Titre | Objectif |
|------|--------|----------|
| E1 | Onboarding entreprise | Inscrire et configurer un compte multi-rôles |
| E2 | Confiance documentaire | Déposer et faire valider RCCM / NIF / ID |
| E3 | Catalogue | Publier et gérer produits MP / finis |
| E4 | Découverte | Chercher selon intention (MP ou finis) |
| E5 | RFQ | Demander et recevoir des devis |
| E6 | Messagerie | Negocier in-app + WhatsApp |
| E7 | Freemium | Limites Free et bénéfices Pro |
| E8 | Administration | Modérer et activer les comptes / plans |
| E9 | Pages publiques | Expliquer l’offre et le cadre légal |

---

## E1 — Onboarding entreprise

### US-1.1 — Inscription (Must)
**En tant que** nouvel acteur agro,  
**je veux** créer un compte avec mon email et un mot de passe,  
**afin de** accéder à la plateforme.

**Critères d’acceptation :**
- [ ] Formulaire : email, mot de passe, confirmation  
- [ ] Email déjà utilisé → message d’erreur clair  
- [ ] Compte créé → redirection vers création d’entreprise  

### US-1.2 — Création entreprise (Must)
**En tant que** utilisateur inscris,  
**je veux** enregistrer ma raison sociale, province, ville et contacts,  
**afin de** apparaître correctement dans l’annuaire.

**Critères d’acceptation :**
- [ ] Champs obligatoires : raison sociale, province, téléphone  
- [ ] Sélection province parmi la liste RDC  
- [ ] WhatsApp optionnel mais recommandé  

### US-1.3 — Rôles multi-sélection (Must)
**En tant que** transformateur,  
**je veux** cocher plusieurs rôles (fournisseur MP, transformateur, acheteur),  
**afin de** utiliser les deux loops sans changer de compte.

**Critères d’acceptation :**
- [ ] Au moins un rôle requis  
- [ ] Les rôles déterminent les CTA visibles (vendre / acheter)  
- [ ] Modification des rôles possible dans les paramètres  

### US-1.4 — Connexion / reset (Must)
**En tant que** utilisateur,  
**je veux** me connecter et réinitialiser mon mot de passe,  
**afin de** retrouver l’accès à mon compte.

---

## E2 — Confiance documentaire

### US-2.1 — Upload documents (Must)
**En tant que** responsable d’entreprise,  
**je veux** téléverser RCCM, NIF et pièce d’identité,  
**afin de** renforcer la crédibilité de mon profil.

**Critères d’acceptation :**
- [ ] Types acceptés : PDF, JPG, PNG  
- [ ] Taille max respectée + message si dépassement  
- [ ] Statut passe à `en_review` après dépôt  

### US-2.2 — Suivi statut docs (Must)
**En tant que** responsable d’entreprise,  
**je veux** voir le statut de mes documents (en revue / accepté / rejeté),  
**afin de** savoir si mon badge est actif.

**Critères d’acceptation :**
- [ ] Motif affiché en cas de rejet  
- [ ] Possibilité de re-soumettre après rejet  

### US-2.3 — Badge public (Must)
**En tant que** acheteur,  
**je veux** voir si une entreprise a des docs validés,  
**afin de** prioriser des partenaires plus crédibles.

---

## E3 — Catalogue

### US-3.1 — Créer un produit (Must)
**En tant que** fournisseur / transformateur,  
**je veux** créer une fiche produit (MP ou fini),  
**afin de** être trouvé dans la recherche.

**Critères d’acceptation :**
- [ ] Type MP ou fini obligatoire  
- [ ] Catégorie, unité, description obligatoires  
- [ ] Prix indicatif optionnel  
- [ ] Au moins une photo optionnelle en MVP mais recommandée  

### US-3.2 — Gérer mon catalogue (Must)
**En tant que** vendeur,  
**je veux** éditer ou archiver mes produits,  
**afin de** garder mon offre à jour.

### US-3.3 — Limite Free (Must)
**En tant que** vendeur Free,  
**je veux** être informé quand j’atteins ma limite de produits,  
**afin de** comprendre l’intérêt du plan Pro.

**Critères d’acceptation :**
- [ ] Blocage création au-delà de la limite  
- [ ] CTA vers page Tarifs / upgrade  

---

## E4 — Découverte

### US-4.1 — Choisir l’intention (Must)
**En tant que** utilisateur,  
**je veux** indiquer si je cherche des matières premières ou des produits finis,  
**afin de** voir des résultats pertinents.

**Critères d’acceptation :**
- [ ] Sélecteur visible sur l’accueil et la recherche  
- [ ] Filtre type produit aligné sur l’intention  

### US-4.2 — Rechercher et filtrer (Must)
**En tant que** acheteur / transformateur,  
**je veux** filtrer par catégorie, province et badge docs,  
**afin de** trouver rapidement un partenaire local.

### US-4.3 — Consulter une fiche (Must)
**En tant que** acheteur,  
**je veux** ouvrir la fiche entreprise + produits,  
**afin de** décider de contacter ou lancer une RFQ.

**Critères d’acceptation :**
- [ ] CTA « Contacter » et « Demander un devis »  
- [ ] Produits featured Pro clairement identifiés sans tromperie  

---

## E5 — RFQ

### US-5.1 — Publier une RFQ (Must)
**En tant que** transformateur / acheteur,  
**je veux** publier une demande de devis détaillée,  
**afin de** recevoir plusieurs offres.

**Critères d’acceptation :**
- [ ] Champs : type, catégorie, quantité, délai, provinces  
- [ ] RFQ ouverte ou ciblée  
- [ ] Confirmation de publication  

### US-5.2 — Répondre à une RFQ (Must)
**En tant que** fournisseur,  
**je veux** répondre avec prix, délai et commentaire,  
**afin de** remporter le besoin.

**Critères d’acceptation :**
- [ ] Une seule réponse active par entreprise et par RFQ (édition possible)  
- [ ] Notification à l’émetteur  

### US-5.3 — Comparer les réponses (Must)
**En tant que** émetteur de RFQ,  
**je veux** voir les réponses dans un tableau,  
**afin de** choisir le meilleur interlocuteur.

### US-5.4 — Clôturer une RFQ (Must)
**En tant que** émetteur,  
**je veux** clôturer ma RFQ,  
**afin de** arrêter les nouvelles réponses.

### US-5.5 — Statut deal déclaratif (Should)
**En tant que** émetteur,  
**je veux** marquer une discussion comme conclue ou sans suite,  
**afin d’**aider la plateforme à mesurer l’impact (sans paiement).

### US-5.6 — Priorité Pro sur RFQ (Must)
**En tant que** vendeur Pro,  
**je veux** être mis en avant sur les RFQ de mon secteur,  
**afin d’**obtenir plus d’opportunités que les Free.

---

## E6 — Messagerie

### US-6.1 — Message in-app (Must)
**En tant que** utilisateur,  
**je veux** envoyer un message lié à un produit ou une RFQ,  
**afin de** négocier sans quitter la plateforme immédiatement.

### US-6.2 — Continuer sur WhatsApp (Must)
**En tant que** utilisateur,  
**je veux** ouvrir WhatsApp prérempli vers le contact de l’entreprise,  
**afin de** finaliser selon mes habitudes locales.

**Critères d’acceptation :**
- [ ] Deep-link `wa.me` avec numéro si renseigné  
- [ ] Message si numéro WhatsApp absent  

---

## E7 — Freemium

### US-7.1 — Voir les tarifs (Must)
**En tant que** vendeur,  
**je veux** consulter la page Tarifs Free vs Pro,  
**afin de** décider d’upgrader.

### US-7.2 — Demander le plan Pro (Must)
**En tant que** vendeur,  
**je veux** soumettre une demande d’abonnement avec preuve de paiement,  
**afin d’**activer les avantages Pro.

**Critères d’acceptation :**
- [ ] Upload preuve (capture Mobile Money / bordereau)  
- [ ] Statut `en attente` jusqu’à validation admin  

### US-7.3 — Avantages Pro actifs (Must)
**En tant que** vendeur Pro,  
**je veux** bénéficier du quota étendu, du badge et du featured,  
**afin d’**obtenir plus de contacts.

---

## E8 — Administration

### US-8.1 — Valider documents (Must)
**En tant qu’**admin,  
**je veux** accepter ou rejeter les documents uploadés,  
**afin de** maintenir un niveau minimal de confiance.

### US-8.2 — Activer Pro (Must)
**En tant qu’**admin,  
**je veux** activer / révoquer un abonnement Pro,  
**afin de** gérer la monétisation MVP.

### US-8.3 — Suspendre un compte (Must)
**En tant qu’**admin,  
**je veux** suspendre une entreprise abusive,  
**afin de** protéger les utilisateurs.

### US-8.4 — Tableau de bord simple (Should)
**En tant qu’**admin,  
**je veux** voir le nombre de comptes, produits et RFQ,  
**afin de** suivre la traction.

---

## E9 — Pages publiques

### US-9.1 — Landing & pédagogie (Must)
**En tant que** visiteur,  
**je veux** comprendre en quoi SokoLink m’aide (2 loops agro),  
**afin de** m’inscrire.

### US-9.2 — CGU & confidentialité (Must)
**En tant que** utilisateur,  
**je veux** accéder aux CGU rappelant que les deals se concluent entre parties,  
**afin de** connaître le cadre légal.

---

## Stories explicitement hors MVP

| ID | Story | Phase |
|----|--------|-------|
| — | Payer via escrow plateforme | V3 |
| — | Commission automatique sur deal | V3 |
| — | Audit usine terrain obligatoire | V2 |
| — | App native stores | post-V1 |
| — | Multi-pays | V4 |

---

## Mapping stories → modules CDC

| Stories | Module CDC |
|---------|------------|
| US-1.x | M1 |
| US-2.x | M2 |
| US-3.x | M3 |
| US-4.x | M4 |
| US-5.x | M5 |
| US-6.x | M6 |
| US-7.x | M7 |
| US-8.x | M8 |
| US-9.x | M9 |

---

## Ordre de sprint suggéré (indicative)

1. **Sprint 0–1 :** E1 + E9 (socle auth + landing)  
2. **Sprint 2 :** E2 + E3 (docs + catalogue)  
3. **Sprint 3 :** E4 (recherche / intentions)  
4. **Sprint 4 :** E5 (RFQ)  
5. **Sprint 5 :** E6 + E7 (messagerie + freemium)  
6. **Sprint 6 :** E8 + durcissement + seed data  

---

## Documents liés

- [`PRD.md`](./PRD.md)  
- [`cahier-des-charges.md`](./cahier-des-charges.md)  
