# Manuel d’utilisation — SokoLink

**Public :** entreprises agroalimentaires en RDC (fournisseurs MP, transformateurs, acheteurs B2B)  
**Version application :** MVP 1.0

---

## 1. Démarrer (OTP + PIN local)

1. Installez l’application mobile SokoLink (Android / iOS).
2. Entrez votre **numéro de téléphone** (RDC) pour recevoir un **code OTP**.
3. Première connexion : complétez le profil (**raison sociale**, **province**, rôles).
4. Créez ensuite un **code PIN local** (4 chiffres minimum). Les prochaines ouvertures de l’app demanderont ce PIN — **pas un nouvel OTP** — pour limiter les coûts SMS.
5. La session reste active **jusqu’à déconnexion** explicite (Profil → Se déconnecter). Après déconnexion, un nouvel OTP est requis.

Rôles possibles :
- Fournisseur de matières premières
- Transformateur / fabricant
- Acheteur B2B

**Hors-ligne :** recherche, catalogue et RFQs déjà consultés restent lisibles via le cache ; une RFQ créée sans réseau est mise en file et envoyée au retour de connexion.

---

## 2. Accueil — deux intentions

Sur l’accueil, choisissez :

| Intention | Usage |
|-----------|--------|
| **Matières premières** | Sourcer pour produire / transformer |
| **Produits finis** | Trouver des biens prêts à commercialiser ou des clients |

---

## 3. Recherche

1. Ouvrez l’onglet **Recherche**.
2. Basculez MP / Produits finis.
3. Filtrez par **province** et **catégorie**.
4. Tapez un mot-clé (produit ou entreprise).
5. Ouvrez une fiche produit ou entreprise.

Les badges peuvent indiquer un plan **Pro** ou des documents validés.

---

## 4. Catalogue (vendre)

1. Profil → **Mon catalogue**.
2. **Ajouter** un produit :
   - type (MP ou produit fini)
   - catégorie agro
   - nom, description, unité
   - prix indicatif (optionnel)
   - province d’origine
3. Modifiez ou archivez un produit via le menu ⋮.

Limites Free : nombre de produits actif limité. Passez en Pro pour élargir.

---

## 5. RFQ (demande de devis)

1. Onglet **RFQ** → créer une demande  
   ou depuis une fiche : **Créer une demande de prix**.
2. Décrivez besoin, quantité, délai.
3. Recevez des réponses d’autres entreprises.
4. Comparez, puis contactez le meilleur interlocuteur.
5. Clôturez la RFQ quand elle n’est plus utile.

---

## 6. Messagerie & WhatsApp

1. Onglet **Messages** ou bouton **Contacter** sur une fiche.
2. Échangez dans l’app.
3. Utilisez **Continuer sur WhatsApp** si le numéro est renseigné.

Les deals se finalisent souvent hors plateforme (banque, Mobile Money) — c’est normal en MVP.

---

## 7. Documents & confiance

Profil → **Documents de l’entreprise** :

- RCCM
- NIF
- Pièce d’identité du gérant

Statuts : en revue → accepté / rejeté. Un admin SokoLink valide les fichiers.

---

## 8. Plan Free / Pro

| | Free | Pro |
|--|------|-----|
| Catalogue | Limité | Étendu |
| RFQ / réponses | Limitées / mois | Prioritaires |
| Visibilité | Standard | Featured / badge |

Demandez le Pro depuis le Profil (preuve de paiement). Validation manuelle admin.

---

## 9. Admin web (équipe SokoLink)

URL : `http://localhost:3200` (ou URL de production)

1. Connexion admin
2. Dashboard : stats, docs en revue, demandes Pro, entreprises
3. Accepter / rejeter documents
4. Activer Pro
5. Suspendre un compte abusif

---

## 10. Bonnes pratiques

- Téléphones WhatsApp à jour
- Descriptions claires + unités (tonne, sac, litre…)
- Prix **indicatifs** seulement
- Lire les [CGU](./legal/cgu.md) avant publication

---

## 11. Support

Email : support@sokolink.cd  
Documentation vivante : voir [docs/index.md](./index.md)
