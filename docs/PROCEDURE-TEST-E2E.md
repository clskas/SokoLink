# Procédure de test end-to-end (E2E) — SokoLink

Ce document décrit, étape par étape, comment tester l'ensemble de la plateforme
SokoLink : application mobile (Flutter), API (NestJS) et back-office web (admin).

> Environnement de test local. En mode démo, aucun SMS n'est envoyé : le code OTP
> est généré côté serveur et **pré-rempli automatiquement** dans l'application.

---

## 1. Prérequis

### 1.1 Services à démarrer (Docker)

Trois conteneurs doivent tourner. Depuis `d:\clsap\DRCconnect` :

```bash
docker compose up -d
```

Vérifier qu'ils sont bien démarrés :

```bash
docker ps
```

| Conteneur            | Rôle             | Port hôte | Doit être    |
| -------------------- | ---------------- | --------- | ------------ |
| `drcconnect-db-1`    | PostgreSQL       | `5434`    | Up (healthy) |
| `drcconnect-api-1`   | API SokoLink     | `3190`    | Up (healthy) |
| `drcconnect-admin-1` | Back-office web  | `3200`    | Up           |

> ⚠️ Si l'application mobile affiche « Impossible d'envoyer l'OTP » ou
> « Service momentanément indisponible », c'est presque toujours que la **base
> `drcconnect-db-1` est arrêtée**. Relancer avec `docker compose up -d`.

### 1.2 Vérifier que l'API répond

- Depuis le PC : http://localhost:3190/v1/health
- Depuis le téléphone (même Wi-Fi) : `http://10.0.92.37:3190/v1/health`

La réponse attendue est : `{"status":"ok","app":"SokoLink API","version":"1.0.0"}`.

### 1.3 Application mobile

L'APK de test est déjà installée sur le téléphone et pointe vers
`http://10.0.92.37:3190/v1`. Pour réinstaller :

```bash
cd mobile
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.92.37:3190/v1
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Pour repartir d'un état vierge (ré-afficher l'écran de connexion OTP) :

```bash
adb shell pm clear com.sokolink.sokolink
```

---

## 2. Comptes de test

### 2.1 Application mobile — connexion par OTP

Tous les comptes mobiles se connectent de la même façon :
**numéro → « Recevoir le code OTP » → code pré-rempli → « Valider » → créer un PIN local**.
Les lancements suivants se font au PIN (aucun SMS).

| Rôle / capacité                            | Téléphone       | Nom                 | Entreprise                | Plan |
| ------------------------------------------ | --------------- | ------------------- | ------------------------- | ---- |
| **ADMIN plateforme**                       | `+243800000000` | Admin SokoLink      | SokoLink Ops              | FREE |
| **Fournisseur MP**                         | `+243810000002` | Jean-Pierre Kalonji | Coopérative Maïs Kwilu    | FREE |
| **Fournisseur MP**                         | `+243810000006` | Emmanuel Kambale    | Cacao Beni Export         | FREE |
| **Transformateur**                         | `+243810000001` | Céline Mbayo        | Minoterie du Fleuve       | PRO  |
| **Transformateur**                         | `+243810000007` | Sylvie Mavinga      | Boissons Congo SARL       | FREE |
| **Fournisseur MP + Transformateur**        | `+243810000003` | Aline Bahati        | Huilerie Sud-Kivu         | PRO  |
| **Fournisseur MP + Transformateur**        | `+243900000001` | Demo SokoLink       | Agro Demo Kin             | FREE |
| **Acheteur B2B**                           | `+243810000004` | Patrick Ilunga      | Distribution Katanga B2B  | FREE |
| **Acheteur B2B**                           | `+243810000005` | Grace Nsimba        | Grossiste Kin Alimentaire | PRO  |

### 2.2 Back-office web — connexion par email / mot de passe

Le back-office **n'utilise pas l'OTP** mais un couple email / mot de passe.

- URL : **http://localhost:3200**
- Email : **`admin@sokolink.cd`**
- Mot de passe : **`AdminSokoLink!2026`**

---

## 3. Scénario E2E complet

L'objectif est de dérouler un cycle métier complet entre un **acheteur**, un
**fournisseur/transformateur** et l'**administrateur**.

### Étape 1 — Première connexion mobile (OTP + PIN)

1. Ouvrir l'app (écran « Connexion par OTP téléphone »).
2. Saisir un numéro, ex. `+243810000004` (acheteur), puis **« Recevoir le code OTP »**.
3. L'écran « Code OTP » s'affiche avec le **code déjà pré-rempli** (mode démo) → **« Valider »**.
4. Créer un **PIN local** (4 à 6 chiffres) puis le confirmer → arrivée sur l'accueil.
5. **Résultat attendu** : l'accueil affiche les rôles de l'entreprise et des actions
   adaptées au rôle (ex. « Créer une RFQ » pour un acheteur).

> Fermer/rouvrir l'app : elle demande désormais le **PIN** (plus d'OTP), et la
> session reste active jusqu'à déconnexion explicite.

### Étape 2 — Parcours Acheteur B2B (`+243810000004`)

1. **Recherche** : onglet Recherche → chercher un produit ou une entreprise.
2. **Contacter depuis une fiche** :
   - Ouvrir une fiche entreprise ou produit → **« Contacter »**.
   - Saisir un message → **« Envoyer »**.
   - **Résultat attendu** : la conversation s'ouvre, le message apparaît à droite
     (bulle « à moi »). *(Correctif appliqué : plus d'erreur à l'envoi.)*
3. **Créer une demande de prix (RFQ)** :
   - Onglet RFQ → bouton **« + »** (visible car acheteur) ou depuis une fiche
     entreprise → **« Créer une demande de prix »**.
   - Remplir le formulaire → envoyer.
   - **Résultat attendu** : la RFQ apparaît dans la liste des RFQ.

### Étape 3 — Parcours Fournisseur / Transformateur (`+243810000003`)

> Astuce : utiliser un 2e téléphone/émulateur, ou se déconnecter puis se
> reconnecter avec l'autre numéro (menu Profil → Se déconnecter).

1. **Catalogue** (transformateur / fournisseur) :
   - Accéder au catalogue → **ajouter un produit**.
   - Le sélecteur de type (MP / Produit fini) s'adapte au rôle :
     - Fournisseur MP → matière première uniquement,
     - Transformateur → produit fini,
     - Double rôle → les deux.
2. **Répondre à une RFQ** :
   - Ouvrir une RFQ ouverte → **répondre** avec un prix/offre.
   - **Résultat attendu** : la réponse est enregistrée et visible par l'acheteur.
3. **Messagerie** :
   - Onglet Messages → ouvrir la conversation initiée par l'acheteur.
   - Répondre via le champ en bas + icône **envoyer**.
   - **Résultat attendu** : l'échange s'affiche dans le bon ordre, bulles
     gauche/droite correctes.

### Étape 4 — Back-office administrateur (http://localhost:3200)

Se connecter avec `admin@sokolink.cd` / `AdminSokoLink!2026`, puis vérifier :

1. **Tableau de bord** : les statistiques se chargent.
2. **Entreprises** : la liste des entreprises s'affiche.
3. **Documents** : valider ou rejeter un document (KYC) en attente.
4. **Demandes Pro** : activer le plan **PRO** d'une entreprise ayant fait la demande.
5. **Suspension** : suspendre puis réactiver une entreprise.
   - **Résultat attendu (côté mobile)** : un compte suspendu se voit refuser les
     actions (message « Compte suspendu. Contactez le support. »).

### Étape 5 — Mode hors-ligne (offline)

1. Sur le téléphone, activer le **mode avion** (ou couper le Wi-Fi).
2. Ouvrir l'app : un bandeau **« Hors-ligne — consultation du cache local »** apparaît.
3. Les écrans déjà consultés restent lisibles (cache).
4. Réactiver le réseau : la synchronisation des actions en file (ex. RFQ créée
   hors-ligne) se rejoue automatiquement.

### Étape 6 — Abonnement & facturation (monétisation)

**Grille tarifaire (par défaut en CDF)** : PRO 60 000/mois ou 600 000/an,
Boost produit 15 000 / 7 jours, Badge Vérifié 90 000/an, Pack de 10 crédits de
mise en relation 30 000.

**Côté mobile (entreprise)**

1. Écran **Profil** : le bandeau affiche le plan (PRO + date d'expiration),
   le badge **Vérifié** et le nombre de **crédits** de mise en relation.
2. « Passer au plan Pro », « Obtenir le badge Vérifié », « Crédits de mise en
   relation » → envoient une **demande de paiement** (statut *en attente*).
3. Catalogue → menu d'un produit → **Booster (7 jours)** → demande de boost.
4. RFQ : au-delà du quota gratuit de réponses, un **crédit** est consommé
   automatiquement ; sans crédit, un message invite à acheter un pack ou passer PRO.

**Côté admin web** (`/dashboard`)

1. Cartes **Revenus & abonnements** : revenu total, ce mois, MRR estimé,
   abonnés PRO actifs, entreprises vérifiées, abonnements expirant sous 7 jours.
2. **Paiements à valider** : *Valider* (applique l'effet : PRO prolongé, produit
   boosté, badge vérifié, crédits ajoutés) ou *Rejeter*.
3. **Enregistrer un paiement** : saisir un paiement reçu (cash / mobile money) —
   validé automatiquement.
4. Tableau **Entreprises** → colonne **Abonnement** : `+ mois PRO`, `Vérifier`,
   `+ crédits`, `Rétrograder`.

---

## 4. Vérifications par rôle (résumé)

| Rôle             | Doit pouvoir                                              | Ne doit pas pouvoir                    |
| ---------------- | -------------------------------------------------------- | ------------------------------------- |
| Acheteur B2B     | Créer des RFQ, contacter, acheter                        | Publier des produits                  |
| Fournisseur MP   | Publier des produits **MP**, répondre aux RFQ, messagerie | Publier des produits finis            |
| Transformateur   | Publier des **produits finis**, gérer le catalogue, RFQ  | —                                     |
| Double rôle      | Vendre MP **et** produits finis                          | —                                     |
| PRO vs FREE      | PRO : fonctions premium débloquées                        | FREE : invitation « Passer au Pro »   |
| ADMIN            | Back-office web (validation, Pro, suspension)             | —                                     |

---

## 4bis. Vérifications de l'audit (corrections & CRUD ajoutés)

À tester après le dernier build pour valider les corrections issues de l'audit
complet du projet :

| Zone        | À vérifier                                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------------------------- |
| Catalogue   | Créer un produit **avec un prix** (ne renvoie plus d'erreur), puis le modifier.                             |
| Fiche produit | Ouvrir un produit depuis la recherche : la **vraie fiche** s'affiche (prix, unité, MOQ, origine, entreprise) avec lien vers l'entreprise. |
| RFQ (achat) | Depuis une fiche produit/entreprise, « Créer une demande de prix » **fonctionne** (type/catégorie hérités). |
| RFQ (form)  | Le formulaire permet de choisir **type, catégorie et provinces ciblées**.                                    |
| RFQ (détail) | La **description** et le **texte des réponses** (prix, délai, commentaire) s'affichent bien.                |
| RFQ (droits) | Le bouton « Répondre » n'apparaît **que** pour un fournisseur/transformateur (pas l'émetteur).              |
| RFQ (CRUD)  | L'émetteur peut **modifier / supprimer** sa demande ; le fournisseur peut **retirer** sa réponse.           |
| Profil      | « Modifier l'entreprise » (nom, province, description, ville, contacts) enregistre correctement.            |
| Documents   | Lister les documents avec leur **statut**, en **ajouter** et en **supprimer**.                              |
| Admin web   | Une entreprise suspendue peut être **réactivée** ; un badge « Vérifié » peut être **retiré**.               |

---

## 4ter. Notifications & changement de statut (nouveau)

Tester sur **deux appareils** : un **acheteur** (ex. `+243810000004`) et un
**fournisseur** (ex. `+243810000002`).

| Étape | Action | Résultat attendu |
| ----- | ------ | ---------------- |
| 1 | Fournisseur **répond** à une RFQ de l'acheteur | L'acheteur voit un **badge rouge** sur la cloche 🔔 de l'accueil (≤ 20 s de polling) |
| 2 | Acheteur ouvre la **cloche** | Une notification « Nouvelle réponse reçue » avec le nom du fournisseur |
| 3 | Acheteur **tape** la notification | Ouvre directement la fiche RFQ ; la notification passe en **lue** |
| 4 | Acheteur ouvre la RFQ → **Statut de l'affaire** | Choix : *En discussion / Affaire conclue / Affaire perdue* |
| 5 | Acheteur choisit **Affaire conclue** | La RFQ passe **Clôturée** + puce « Affaire conclue » ; le fournisseur reçoit une notif « Statut d'une demande mis à jour » |
| 6 | Envoyer un **message** à une autre entreprise | Le destinataire reçoit une notif « Nouveau message » qui ouvre la conversation |
| 7 | Admin **valide/rejette un document**, **confirme un paiement** ou **active le PRO** | L'entreprise concernée reçoit la notif correspondante (Document, Paiement, Abonnement) |
| 8 | Cloche → **« Tout marquer comme lu »** (icône ✓✓) | Le badge disparaît, compteur remis à zéro |

> Les notifications sont **par entreprise** et remontées par *polling* (20 s) —
> pas de push serveur en environnement local.

> ℹ️ L'adresse `10.0.92.37` est l'IP Wi-Fi **de cette machine**. Si l'IP change,
> reconstruire l'APK avec `--dart-define=API_BASE_URL=http://<nouvelle-IP>:3190/v1`.

---

## 5. Dépannage (troubleshooting)

| Symptôme                                             | Cause probable                              | Solution                                                        |
| --------------------------------------------------- | ------------------------------------------- | -------------------------------------------------------------- |
| « Impossible d'envoyer l'OTP »                      | Base `drcconnect-db-1` arrêtée              | `docker compose up -d`                                          |
| « Service momentanément indisponible » (OTP)        | API en erreur 5xx (souvent la base)         | Vérifier les logs : `docker logs drcconnect-api-1 --tail 50`   |
| « Serveur injoignable »                             | Téléphone hors du réseau / mauvaise IP      | Vérifier `http://10.0.92.37:3190/v1/health` depuis le téléphone |
| L'écran de code OTP ne s'affiche pas                | (Corrigé) ancien build                       | Réinstaller l'APK à jour                                        |
| Erreur au bouton « Envoyer » (message)              | (Corrigé) champs API/app désalignés         | Réinstaller l'APK à jour                                        |
| Admin web ne répond pas                             | Conteneur admin arrêté                        | `docker restart drcconnect-admin-1`                            |

### Commandes utiles

```bash
# Logs de l'API
docker logs drcconnect-api-1 --tail 50

# Santé API
curl http://localhost:3190/v1/health

# Repartir d'une app mobile vierge
adb shell pm clear com.sokolink.sokolink

# Régénérer des données de démo
cd api && npm run prisma:mock
```
