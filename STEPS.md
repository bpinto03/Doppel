# STEPS.md — Doppel : de zéro à la publication

> Cochez les cases au fur et à mesure. Chaque phase se termine par une **porte de validation (gate)** : on ne passe pas à la suivante tant qu'elle n'est pas franchie.
> Durées indicatives pour environ 8 à 10 h/semaine. À adapter.

**Vue d'ensemble**

| Phase | Contenu | Durée indicative |
|-------|---------|------------------|
| 0 | *(Optionnelle)* Cadrage, légal, comptes, environnement | 1 semaine |
| 1 | Prototype de la mécanique | 1 à 2 semaines |
| 2 | Jeu de base + "juice" | 2 semaines |
| 3 | Méta-jeu (menus, pièces, thèmes, défis) | 2 semaines |
| 4 | Monétisation (pubs, consentement, achat) | 1 à 2 semaines |
| 5 | Qualité, performance, accessibilité | 1 à 2 semaines |
| 6 | Préparation du store | 1 semaine |
| 7 | Test fermé Google Play (14 jours minimum) | 2 à 3 semaines (en partie en parallèle) |
| 8 | Production et lancement | 1 semaine |
| 9 | Post-lancement et itérations | continu |

---

## Phase 0 — Cadrage, légal, comptes, environnement *(optionnelle)*

> Cette phase est optionnelle : on peut passer directement à la phase 1 et y revenir au besoin. Repères utiles :
> - l'**environnement de dev** (0.4) doit être prêt avant de tester sur téléphone (phase 1) ;
> - le **compte Play Console** (0.3) doit exister avant la phase 7 (test fermé) ;
> - le **cadre d'activité** (0.1) doit être décidé avant l'activation des vraies pubs (voir phase 6).

### 0.1 Légal et administratif (peut attendre la phase 6)
- [ ] Décider du cadre d'activité (micro-entreprise ou autre) et en parler à l'URSSAF / un expert-comptable
- [ ] Comprendre comment seront déclarés les revenus publicitaires et les achats in-app

### 0.2 Identité du projet
- [x] Nom définitif choisi : **Doppel** (vérifications faites : pas de marque existante, nom libre sur Google Play, domaine et pseudos disponibles)
- [x] Définir l'identifiant de package : `com.rumble.doppel` — **définitif, impossible à changer après publication**
- [x] Créer un dépôt Git privé, ajouter un `.gitignore` adapté à Godot
- [x] Copier `CAHIER_DES_CHARGES.md` et `STEPS.md` à la racine du dépôt

### 0.3 Comptes
- [ ] Créer le compte développeur **Google Play Console** (frais d'inscription uniques, vérification d'identité)
- [ ] Décider : compte **personnel** (test fermé 12 testeurs / 14 jours obligatoire) ou compte **organisation** (exempté, mais nécessite un numéro D-U-N-S qui peut prendre du temps) — vérifier les règles actuelles dans l'aide Google Play
- [ ] Créer un compte **AdMob**, enregistrer l'app, noter les IDs de test et les IDs réels
- [ ] Prévoir où héberger la politique de confidentialité (page web publique, ex : GitHub Pages)

### 0.4 Environnement de dev
- [x] Installer la version stable de **Godot 4.x** et la figer pour tout le projet
- [x] Installer le **JDK** et l'**Android SDK** requis, configurer Godot (Éditeur > Paramètres > Export > Android)
- [x] Installer les **modèles d'export** Android
- [x] Préparer un téléphone Android de test (mode développeur, débogage USB) et si possible un deuxième appareil plus modeste
- [x] Vérifier qu'un projet "Hello World" s'exporte et s'installe sur le téléphone
- [x] Générer un **keystore** de signature et le **sauvegarder** (copie hors ligne + gestionnaire de mots de passe)

### 0.5 Recrutement précoce des testeurs
- [ ] Faire une liste d'au moins 15 personnes avec un téléphone Android (amis, famille, collègues, communautés Godot / indie / Reddit / Discord)
- [ ] Leur demander s'ils accepteraient de tester plus tard (il faudra leur adresse Gmail)

**✅ Gate 0 (si la phase est suivie) :** comptes créés, un APK de test s'installe sur mon téléphone.

---

## Phase 1 — Prototype de la mécanique (sans graphismes soignés)

Objectif : **savoir si le jeu est fun**, rien d'autre.

- [x] Créer la scène de jeu avec une grille 6×6 (rectangles et chiffres suffisent)
- [x] Coder la structure de données de la grille (tableau 2D) dans un script **indépendant de l'affichage**
- [x] Générer les tuiles proposées (niveaux pondérés) avec aperçu de la suivante
- [x] Gérer le tap sur une colonne gauche : pose de la tuile + **pose du reflet** à droite
- [x] Appliquer la **gravité**
- [x] Coder les **fusions** (voisins orthogonaux de même niveau, niveau +1)
- [x] Coder la **réévaluation en boucle** pour les chaînes (combos)
- [x] Gérer la fusion à travers l'axe central
- [x] Coder la **détection de fin de partie**
- [x] Afficher score, record, niveau max
- [x] Ajouter un bouton **Recommencer**
- [x] Écrire quelques **tests simples** de la logique (cas de fusion, chaînes, fin de partie)
- [x] Externaliser les paramètres d'équilibrage (taille de grille, pondérations, points)
- [x] Enregistrer les événements de résolution de chaque tour (pose, fusions, chutes) et les tester
- [x] Rejouer les événements avec des animations simples (pulsation, chute, « x2 », saut par tap)
- [x] Poser au relâchement du doigt et afficher l'aperçu fantôme de la tuile et de son reflet
- [x] Accepter le toucher sur les deux moitiés (tuile toujours à gauche, reflet toujours à droite)
- [x] Écrire les scénarios du mini tutoriel (pose, fusion, fusion à travers l'axe) et leurs tests unitaires
- [x] Mini tutoriel jouable en 3 étapes, passable, accessible via un bouton « ? » (affiché à chaque lancement, sans sauvegarde) ; colonne cible et sa symétrique acceptées et mises en évidence
- [x] Implémenter l'option d'équilibrage "reflet déformé" et la comparer à la version de base
- [x] Exporter un APK et y jouer sur téléphone

### Test de validation
- [ ] Faire tester à **5 personnes** sans explication préalable (observer en silence)
- [ ] Noter : comprennent-elles seules ? Relancent-elles une partie sans qu'on leur demande ? Combien de parties d'affilée ?
- [ ] Ajuster la mécanique (taille de grille, pondérations, leviers d'équilibrage) et retester si besoin

**✅ Gate 1 (go / no-go) :** au moins 3 testeurs sur 5 relancent spontanément une partie. Sinon : retravailler la mécanique avant d'aller plus loin.

---

## Phase 2 — Jeu de base et "juice"

### 2.1 Fondations de production
- [x] Mettre en place la structure de dossiers (scenes / scripts / assets / data)
- [x] Configurer le projet : portrait, 1080×1920, stretch `canvas_items`, renderer **Compatibility**
- [x] Gérer les zones sûres (encoche, barre de navigation)
- [x] Créer les autoloads : `SaveManager`, `AudioManager`, `Settings`, `I18n`

### 2.2 Direction artistique
- [x] Choisir une palette de couleurs lisible et une police
- [x] Concevoir les visuels de tuiles (niveaux 1 à 12), la distinction repose sur la couleur et le chiffre
- [x] Concevoir l'arrière-plan, la grille, l'axe central

### 2.3 Gameplay animé
- [x] Animer la chute des tuiles (`Tween`)
- [x] Animer la fusion ("pop", léger rebond)
- [x] Animer les chaînes avec intensité croissante
- [x] Ajouter particules (`CPUParticles2D`) et petit tremblement d'écran sur gros combos
- [x] Animer et soigner l'**aperçu du reflet** (version simple faite en phase 1)
- [x] Afficher les messages de combo, sobres

### 2.4 Audio et haptique
- [x] Ajouter les effets sonores (pose, fusion, chaîne avec hauteur croissante, fin de partie)
- [x] Ajouter une musique d'ambiance en boucle
- [x] Ajouter une vibration légère (désactivable)
- [ ] Noter les **licences** de chaque asset audio et visuel (fichier `CREDITS.md`)

### 2.5 Persistance
- [ ] Sauvegarder record, réglages, et **la partie en cours** (reprise après interruption)
- [ ] Gérer pause, mise en veille, retour d'application, appel entrant

**✅ Gate 2 :** le jeu est agréable à jouer pendant 10 minutes d'affilée, sur téléphone, et les retours sont positifs.

---

## Phase 3 — Méta-jeu : menus, pièces, thèmes, défis

### 3.1 Navigation et écrans
- [ ] Écran d'accueil (Jouer, Défi du jour, Boutique, Réglages)
- [ ] Écran de fin de partie (score, record, pièces gagnées, rejouer)
- [ ] Écran de pause
- [ ] Écran de réglages (son, musique, vibration, langue, thème Papier / Nuit) ; retirer les boutons de debug « Thème », « Vib » et « Musique » du HUD et les logs de debug FPS (`FrameRateProbe`) et latence audio (`AudioLatencyProbe`). Mode daltonisme à reconsidérer en phase 3 (par exemple palette alternative à contraste renforcé), à décider avec le développeur
- [ ] Revoir la condition de démarrage de la musique quand le menu d'accueil existera : la musique doit continuer entre menu et partie sans redémarrer (aujourd'hui, l'écran de jeu la lance à son entrée et l'arrête à sa sortie)
- [ ] **Tutoriel** : version finale (mémoriser qu'il a été vu, visuels soignés ; version simple faite en phase 1)

### 3.2 Pièces et boutique
- [ ] Définir la formule des pièces gagnées par partie
- [ ] Créer 4 à 6 thèmes de tuiles de boutique, en plus des deux thèmes gratuits Papier et Nuit (mettre à jour les exemples de thèmes du cahier des charges)
- [ ] Coder la boutique (achat avec pièces, thème équipé, sauvegarde)

### 3.3 Défis
- [ ] **Défi quotidien** : graine dérivée de la date UTC, score du jour, une tentative ou plusieurs selon le design
- [ ] Gérer le changement de jour (fuseau, triche à l'horloge acceptable en local)
- [ ] **Objectifs** courts (liste de missions, progression, récompense en pièces)
- [ ] Série de jours consécutifs avec petite récompense

### 3.4 Textes et langues
- [ ] Externaliser tous les textes dans un fichier de traduction
- [ ] Traduire en français et en anglais
- [ ] Vérifier que les textes ne débordent pas dans les deux langues

**✅ Gate 3 :** un nouveau joueur peut installer, comprendre, jouer, gagner des pièces, changer de thème, et relever un défi sans aide.

---

## Phase 4 — Monétisation

### 4.1 Publicités
- [ ] Choisir et tester le plugin AdMob pour Godot (compatibilité avec ma version de Godot, maintenance)
- [ ] Intégrer avec les **IDs de test uniquement**
- [ ] Coder `AdsManager` (chargement, affichage, callbacks, échecs réseau)
- [ ] **Vidéo récompensée** : "Continuer" (une fois par partie), "Doubler les pièces"
- [ ] **Interstitiel** : en fin de partie, pas avant la 3e partie, au moins 3 minutes d'écart, jamais en cours de partie
- [ ] Vérifier que le jeu reste parfaitement jouable **hors-ligne** (pub indisponible = pas de blocage)

### 4.2 Consentement et confidentialité
- [ ] Intégrer le message de consentement (UMP / CMP) pour l'Europe, avant le chargement des pubs
- [ ] Ajouter un bouton "Gérer mes choix pub" dans les réglages
- [ ] Rédiger la **politique de confidentialité** (données collectées, pubs, contact) et la publier sur une URL publique

### 4.3 Achat "Sans pub"
- [ ] Intégrer un plugin Google Play Billing pour Godot (à vérifier)
- [ ] Créer le produit in-app dans Play Console (produit non consommable)
- [ ] Coder l'achat, la **restauration des achats**, et la désactivation des interstitiels
- [ ] Tester avec un compte testeur de licence

### 4.4 Bascule vers la production
- [ ] Remplacer les IDs de test par les IDs réels uniquement dans le build de release
- [ ] **Ne jamais cliquer sur ses propres pubs réelles** (risque de suspension du compte AdMob)

**✅ Gate 4 :** pubs de test affichées correctement, consentement fonctionnel, achat "sans pub" testé de bout en bout.

---

## Phase 5 — Qualité, performance, accessibilité

- [ ] Tester sur au moins **2 téléphones** différents (dont un modeste) et plusieurs tailles d'écran
- [ ] Mesurer les FPS et corriger les ralentissements (particules, shaders, trop de nœuds)
- [ ] Vérifier le **poids** de l'APK / AAB et optimiser (textures, sons)
- [ ] Vérifier la consommation batterie en menu et en pause
- [ ] Tester les cas limites : rotation bloquée, retour d'app, appel, mode avion, stockage plein, application tuée en cours de partie
- [ ] Tester sans réseau et avec réseau instable
- [ ] Vérifier la lisibilité en plein soleil (et le mode daltonisme s'il a été retenu en phase 3)
- [ ] Vérifier les zones sûres sur écrans à encoche
- [ ] Corriger les bugs, geler les fonctionnalités (**feature freeze**)
- [ ] Faire une passe d'équilibrage finale (difficulté, pondérations, pièces, fréquence des pubs)
- [ ] Nettoyer le projet (assets inutilisés, logs de debug)
- [ ] Faire relire les textes (fautes, ton, cohérence FR / EN)

**✅ Gate 5 :** aucune crash connu, 60 FPS sur l'appareil de référence, build stable prêt à être testé par d'autres.

---

## Phase 6 — Préparation du store

### 6.1 Build de release
- [ ] Configurer l'export Android : build **gradle personnalisé** si le plugin le demande, architecture **64 bits** (arm64-v8a), icônes, nom, version
- [ ] Définir `versionCode` (entier croissant) et `versionName`
- [ ] Vérifier la version cible d'Android (**target SDK**) exigée par Google Play pour les nouvelles apps, et la respecter
- [ ] Exporter un **AAB** signé (format requis par Google Play)
- [ ] Activer **Play App Signing** dans Play Console
- [ ] Tester l'installation d'un build release (et non uniquement debug)

### 6.2 Fiche store
- [ ] Rédiger titre, description courte et description longue (FR + EN), avec mots-clés pertinents (ASO)
- [ ] Créer l'**icône** (512×512), la **feature graphic** (1024×500)
- [ ] Capturer au moins 4 **captures d'écran** soignées, avec légendes si possible
- [ ] (Optionnel) Réaliser une courte vidéo de présentation
- [ ] Choisir la catégorie (Jeux > Puzzle) et les tags

### 6.3 Formulaires et déclarations Play Console
- [ ] **Sécurité des données (Data Safety)** : déclarer pubs, identifiants publicitaires, données collectées par les SDK
- [ ] **Classification du contenu** (questionnaire)
- [ ] **Public cible** : adultes / adolescents, **pas** les enfants
- [ ] **Déclaration de publicité** : l'app contient des pubs
- [ ] URL de la **politique de confidentialité**
- [ ] Pays de distribution, prix (gratuit), contacts, e-mail support
- [ ] Vérifier la section "App content" jusqu'à ce que tout soit vert

### 6.3 bis Cadre d'activité (avant les vrais revenus)
- [ ] Avoir décidé du cadre d'activité (voir 0.1) **avant** d'activer les vrais IDs de pub et la production
- [ ] Vérifier avec l'URSSAF / un expert-comptable la catégorie de revenus, la TVA et la déclaration des revenus Google Play / AdMob

### 6.4 Assets de lancement
- [ ] Créer une page web simple ou une page de présentation (optionnel mais utile)
- [ ] Préparer 2 ou 3 vidéos courtes de gameplay (format vertical) pour les réseaux

**✅ Gate 6 :** AAB signé prêt, fiche store complète, toutes les déclarations remplies.

---

## Phase 7 — Test fermé Google Play (si compte personnel récent)

> À lancer **dès que le build est stable** (fin de phase 5). Les 14 jours tournent en parallèle de la finition.

- [ ] Créer une **piste de test fermé** dans Play Console
- [ ] Importer l'AAB et créer la release de test
- [ ] Créer une liste de testeurs (adresses Gmail) ou un groupe Google
- [ ] Recruter **au moins 12 testeurs** (viser 15 à 20 pour avoir de la marge)
- [ ] Envoyer le lien d'inscription (opt-in) à chaque testeur
- [ ] Vérifier que tous sont **inscrits et actifs** pendant **14 jours continus**
- [ ] Demander aux testeurs de **réellement utiliser** l'app (pas seulement l'installer)
- [ ] **Ne pas suspendre la piste** pendant les 14 jours
- [ ] Collecter les retours (formulaire simple, groupe de discussion)
- [ ] Corriger les bugs remontés, publier des mises à jour de la piste si besoin
- [ ] À la fin, **demander l'accès à la production** dans Play Console et répondre aux questions demandées

> Si compte organisation ou ancien compte personnel exempté : sauter les exigences de nombre de testeurs, mais **garder un test interne / fermé** quand même pour valider le build.

**✅ Gate 7 :** accès à la production accordé, retours critiques traités.

---

## Phase 8 — Production et lancement

- [ ] Créer la release de **production** avec le dernier AAB validé
- [ ] Choisir un **déploiement progressif** (par exemple 20 % puis 50 % puis 100 %) pour limiter les risques
- [ ] Vérifier une dernière fois : IDs AdMob **réels**, achat in-app actif, politique de confidentialité en ligne, consentement OK
- [ ] Soumettre pour examen et attendre la validation (de quelques heures à plusieurs jours)
- [ ] Une fois publié : installer depuis le **vrai Play Store** et vérifier tout le parcours (pubs réelles à ne pas cliquer, consentement, achat)
- [ ] Annoncer le lancement : proches, communautés, réseaux (vidéos verticales courtes), éventuellement Product Hunt / Reddit r/AndroidGaming selon les règles de chaque communauté
- [ ] Demander des avis aux premiers joueurs (sans les forcer ni les récompenser indûment)

**✅ Gate 8 :** jeu en production, installable par tous, pas de crash au lancement.

---

## Phase 9 — Post-lancement et itérations

### 9.1 Surveillance (les 2 premières semaines, chaque jour)
- [ ] **Play Console** : crashs, ANR, avis, installations, désinstallations
- [ ] **AdMob** : impressions, eCPM, revenus, taux de remplissage
- [ ] Répondre aux avis (surtout négatifs, avec courtoisie)

### 9.2 Indicateurs
- [ ] Mesurer rétention J1 / J7 / J30, durée de session, parties par session
- [ ] Mesurer revenu par joueur actif (ARPDAU) et conversion vers l'achat "sans pub"
- [ ] Comparer aux seuils définis dans le cahier des charges (section 10)

### 9.3 Itérations
- [ ] Corriger les bugs prioritaires (mise à jour 1.0.1)
- [ ] Ajuster l'équilibrage (difficulté, fréquence des pubs, récompenses)
- [ ] Tester des améliorations d'ASO (titre, icône, captures)
- [ ] Planifier la **v1.1** : classement Google Play Games, bonus (bombe, swap, rewind), nouveaux thèmes, événements saisonniers
- [ ] Décider : continuer, pivoter, ou arrêter selon les critères de décision

### 9.4 Administratif
- [ ] Déclarer les revenus selon le cadre choisi en phase 0
- [ ] Renseigner les informations fiscales et de paiement dans AdMob (seuil de paiement, vérification d'adresse)
- [ ] Conserver les justificatifs et licences d'assets

---

## Check-list finale "prêt à publier"

- [ ] Statut d'activité défini
- [ ] Jeu stable, testé sur plusieurs appareils, hors-ligne OK
- [ ] 60 FPS sur l'appareil de référence, poids raisonnable
- [ ] Pubs : IDs réels en release, consentement OK, fréquence raisonnable
- [ ] Achat "sans pub" fonctionnel, restauration OK
- [ ] Politique de confidentialité en ligne, déclarations Play Console complètes
- [ ] AAB signé, `versionCode` correct, keystore sauvegardé
- [ ] Fiche store FR / EN, icône, visuels, captures
- [ ] Test fermé terminé, accès à la production obtenu
- [ ] Déploiement progressif configuré
- [ ] Plan de suivi post-lancement prêt
