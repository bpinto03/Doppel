# Cahier des charges — Doppel

> Version 0.1 — document vivant. Les valeurs marquées **[À TESTER]** sont des hypothèses à ajuster pendant le prototype.

---

## 1. Contexte et objectifs

### 1.1 Contexte
Projet personnel mené en parallèle d'un emploi à temps plein (ESN). Développement en soirées et week-ends, par une seule personne, avec **Godot 4**. Cible : **Android** (Google Play).

### 1.2 Objectifs
| # | Objectif | Indicateur de réussite |
|---|----------|------------------------|
| O1 | Sortir un jeu puzzle casual complet et publié | App en production sur Google Play |
| O2 | Valider que le concept est addictif avant d'investir plus | Rétention J1 / J7 mesurée sur de vrais joueurs |
| O3 | Générer un petit revenu (pubs + achat "sans pub") | ARPDAU et revenus suivis dans AdMob / Play Console |
| O4 | Garder un périmètre réaliste | MVP livrable en environ 8 à 12 semaines à temps partiel |

### 1.3 Non-objectifs (hors périmètre MVP)
- Multijoueur, comptes utilisateurs, serveur dédié
- iOS (possible plus tard)
- Classements en ligne (prévu en v1.1)
- Mode histoire, narration, personnages

---

## 2. Public cible

- Joueurs casual, 16 à 45 ans, qui jouent en transports / pauses / canapé.
- Familiers de 2048, Block Blast, Suika, Merge Dragons-like.
- Sessions de 2 à 5 minutes, jeu à une main, sans connexion obligatoire.
- **Le jeu ne cible pas les enfants** (important pour les règles pub / Google Play).

---

## 3. Concept

Une grille de tuiles numérotées partagée autour d'un **axe central miroir**. Le joueur pose une tuile côté gauche ; **son reflet tombe automatiquement côté droit**. Les tuiles identiques adjacentes fusionnent en une tuile de niveau supérieur, avec des **réactions en chaîne**. Le joueur doit gérer deux côtés à la fois. La partie se termine quand il n'y a plus de place pour poser.

**Pitch en une phrase :** *"2048 qui se joue en miroir : chaque coup compte double."*

**Promesse de gameplay :** facile à comprendre en 5 secondes, difficile à maîtriser, parties courtes, envie de relancer immédiatement.

---

## 4. Règles du jeu (version 1)

### 4.1 Grille
- Grille de **6 colonnes × 6 lignes** : 3 colonnes à gauche, 3 colonnes à droite de l'axe central. **[À TESTER]** (autres tailles à essayer : 6×7, 6×5)
- Gravité vers le bas : les tuiles tombent jusqu'à la tuile ou le bas de la grille.
- Colonnes numérotées de gauche à droite : G1, G2, G3 | D1, D2, D3. G3 et D1 sont adjacentes à l'axe, donc **voisines entre elles**.
- Le reflet d'une tuile posée en G1 apparaît en D3, G2 en D2, G3 en D1.

### 4.2 Tuiles
- Les tuiles ont un **niveau** de 1 à 12 (valeur affichée = 2^niveau : 2, 4, 8, ... 4096).
- Chaque tour, une tuile est proposée (le joueur voit aussi la **suivante** en aperçu).
- Niveau de la tuile proposée : tirage pondéré. Les pondérations évoluent par paliers selon la plus grosse tuile atteinte dans la partie (poids relatifs) : **[À TESTER]**
  - dès le début : 2 (60), 4 (30), 8 (10) ;
  - à partir de 128 : 2 (50), 4 (30), 8 (15), 16 (5) ;
  - à partir de 256 : 2 (40), 4 (30), 8 (20), 16 (8), 32 (2) ;
  - à partir de 512 : 2 (30), 4 (30), 8 (20), 16 (13), 32 (6), 64 (1).

### 4.3 Tour de jeu
1. Le joueur touche une colonne, sur n'importe quelle moitié. Toucher une colonne de droite revient à choisir sa colonne symétrique à gauche.
2. La tuile tombe toujours à gauche, dans la colonne choisie ; son **reflet** tombe toujours dans la colonne symétrique à droite.
3. Les fusions sont résolues (voir 4.4).
4. Si la partie n'est pas terminée, on passe à la tuile suivante.

### 4.4 Fusions
- Deux tuiles (ou plus) de **même niveau**, adjacentes en orthogonal (haut / bas / gauche / droite), fusionnent en **une seule tuile de niveau +1**.
- La tuile résultante apparaît à l'emplacement de la dernière tuile posée (ou le plus bas du groupe).
- Après une fusion, la gravité s'applique, puis on **réévalue la grille** : si une nouvelle fusion est possible, c'est une **chaîne** (combo +1).
- Une fusion à travers l'axe (G3 et D1) est autorisée : la tuile résultante reste du côté du joueur (gauche), la tuile miroir correspondante disparaît.

### 4.5 Équilibrage : risque connu
Si la fusion centrale est toujours avantageuse, la stratégie dominante sera "toujours poser en G3". À tester dès le prototype, avec ces leviers (en choisir un ou deux) :
- **Reflet déformé :** toutes les N poses (par exemple 5), le reflet apparaît avec un niveau +1 ou dans une colonne décalée. **[Option par défaut à tester en premier]**
- **Tuiles piégées :** de temps en temps, une tuile "pierre" non fusionnable apparaît d'un côté.
- **Fusion centrale coûteuse :** la fusion à travers l'axe rapporte moins de points.

### 4.6 Fin de partie
La partie se termine lorsque **le joueur n'a plus aucune colonne** où poser sa tuile **et** son reflet (colonne gauche ou colonne droite symétrique pleine) et qu'aucune fusion n'est possible pour libérer de la place.

### 4.7 Score
- Points d'une fusion = valeur de la tuile obtenue × **multiplicateur de chaîne** (×1, ×2, ×3...). **[À TESTER]**
- Le score final, le **record** et le niveau maximum atteint sont affichés en fin de partie.

---

## 5. Modes et progression

### 5.1 Modes
| Mode | Description | MVP |
|------|-------------|-----|
| Classique | Partie libre, tirages aléatoires | Oui |
| Défi quotidien | Même suite de tuiles pour tous (graine = date), score à battre | Oui |
| Défis / objectifs | Missions courtes ("atteins le niveau 7", "fais une chaîne de 4") | Oui |
| Classement en ligne | Via Google Play Games | v1.1 |

### 5.2 Progression légère
- **Pièces** gagnées à chaque partie (selon score et niveau max) et via les défis.
- Boutique de **thèmes de tuiles** (par exemple : néon, bonbons, pixel art, marbre) achetables avec des pièces. MVP : 4 à 6 thèmes.
- Série de jours consécutifs ("streak") avec petite récompense.
- Pas d'énergie, pas de timer bloquant, pas de pay-to-win.

### 5.3 Bonus (optionnel MVP, sinon v1.1)
- **Bombe :** retire une tuile.
- **Swap :** échange deux tuiles.
- **Rewind :** annule le dernier coup.
- Obtenus via pubs récompensées ou pièces. Limités par partie pour ne pas casser l'équilibre.

---

## 6. Monétisation

| Source | Détail |
|--------|--------|
| Vidéo récompensée | "Continuer" après une défaite (une fois par partie), doubler les pièces de fin de partie, obtenir un bonus |
| Interstitiel | À la fin d'une partie, avec **fréquence limitée** : au moins 3 minutes d'écart et pas avant la 3e partie. **Jamais en cours de partie.** **[À TESTER]** |
| Achat in-app "Sans pub" | Environ 2 à 3 € : supprime les interstitiels (les vidéos récompensées restent optionnelles) |
| Bannière | Aucune (nuit à l'expérience pour un faible gain) |

**Règles :**
- Le jeu doit rester **entièrement jouable hors-ligne** (les pubs échouent proprement).
- Les pubs de test (IDs de test AdMob) sont obligatoires pendant tout le développement.
- Message de **consentement** (RGPD / UMP) affiché avant les pubs pour les joueurs européens.

---

## 7. Expérience utilisateur et direction artistique

### 7.1 Principes
- **Une main, portrait**, boutons larges et zones tactiles généreuses.
- **Relance instantanée** : un tap pour recommencer, sans écran intermédiaire lourd.
- Lisibilité d'abord : contraste fort, chiffres grands. Les tuiles se distinguent par la couleur et le chiffre, sans symbole. Pas de mode daltonisme au MVP (décidé le 2026-10-31) : la valeur affichée sur chaque tuile suffit à distinguer les niveaux.
- Style visuel simple, cohérent, léger à produire (formes vectorielles / flat design).

### 7.2 Écrans
1. Écran titre / accueil (Jouer, Défi du jour, Boutique, Tutoriel, Réglages)
2. Tutoriel court (3 étapes max, jouable), ouvert uniquement depuis le bouton Tutoriel de l'accueil : il n'est jamais lancé automatiquement et il n'y a pas de bouton « ? » en partie. Il se termine sur l'accueil.
3. Écran de jeu (score, record, tuile suivante, pause). La pause donne aussi accès aux réglages de sons, musique, vibration et tremblement d'écran, sans quitter la partie.
4. Fin de partie (score, record, pièces gagnées, rejouer, pub récompensée)
5. Défis et objectifs
6. Boutique de thèmes
7. Réglages (son, vibration, langue, consentement pubs, achat "sans pub", restaurer l'achat, politique de confidentialité)

### 7.3 "Juice" (cœur de l'effet addictif)
- Animations de chute, de fusion (petit "pop"), de chaîne (intensité croissante).
- Particules, léger tremblement d'écran sur gros combos.
- Sons dont la **hauteur monte** à chaque maillon de chaîne.
- Vibration haptique légère (désactivable).
- Messages de combo ("Super !", "Incroyable !") sobres.

### 7.4 Audio
- 1 musique d'ambiance légère (boucle, désactivable), 6 à 10 effets sonores.
- Sons et musique libres de droits ou créés soi-même ; **conserver les licences et crédits**.

### 7.5 Langues
Français et anglais dès le MVP (textes externalisés dans un fichier de traduction).

---

## 8. Spécifications techniques

### 8.1 Moteur et outils
- **Godot 4.x** (version stable à figer au démarrage et à ne pas changer en cours de route).
- GDScript.
- Renderer **Compatibility** (meilleure compatibilité sur les téléphones d'entrée de gamme).
- Git pour le versionnement (dépôt privé).

### 8.2 Affichage
- Résolution de base **1080 × 1920**, orientation **portrait** verrouillée.
- Stretch mode `canvas_items`, aspect `expand`, gestion des **zones sûres** (encoche, barre de navigation).

### 8.3 Architecture proposée
```
res://
  scenes/
    main.tscn            # point d'entrée / navigation
    game/                # board.tscn, tile.tscn, hud.tscn
    ui/                  # menu, shop, daily, settings, game_over
  scripts/
    core/                # grid.gd, merge_logic.gd, tile_spawner.gd, score.gd
    autoload/            # save_manager.gd, audio_manager.gd, ads_manager.gd,
                         # iap_manager.gd, settings.gd, i18n.gd
  assets/                # sprites, fonts, audio, themes
  data/                  # config d'équilibrage (JSON / Resource)
```

### 8.4 Principes techniques
- **Séparer logique et affichage** : la logique de grille (fusions, gravité, chaînes, fin de partie) doit être pure et testable sans interface.
- **Aléatoire reproductible** : `RandomNumberGenerator` avec graine ; défi quotidien = graine dérivée de la date (UTC).
- **Sauvegarde locale** (`user://`, JSON ou ConfigFile) : record, pièces, thèmes débloqués, réglages, état d'achat, défis, partie en cours.
- **Animations** avec `Tween` ; particules en `CPUParticles2D` (plus sûr en Compatibility).
- **Équilibrage externalisé** dans un fichier de données pour ajuster sans toucher au code.
- Pubs : plugin AdMob pour Godot (communautaire, **à vérifier** : compatibilité avec la version de Godot choisie et maintenance).
- Achat in-app : plugin Google Play Billing pour Godot (**à vérifier** de la même façon).

### 8.5 Exigences non fonctionnelles
| Exigence | Cible |
|----------|-------|
| Fluidité | 60 FPS sur un téléphone d'entrée de gamme (à définir : appareil de référence) |
| Poids | Idéalement moins de 50 Mo |
| Hors-ligne | Totalement jouable sans réseau |
| Démarrage | Moins de 3 secondes jusqu'au menu |
| Stabilité | Aucun crash bloquant ; taux de crash Play Console faible |
| Batterie | Pas de calcul inutile en pause / menu |
| Interruptions | Appel, mise en veille, retour d'app : la partie reprend correctement |
| Accessibilité | Textes lisibles, vibration et son désactivables ; pas de mode daltonisme au MVP, la valeur affichée sur chaque tuile distingue les niveaux |

---

## 9. Conformité, légal et store

- **Contrat de travail (ESN)** : vérifier clause d'exclusivité / non-concurrence / propriété intellectuelle avant de commencer. Ne pas utiliser le matériel ni le temps de travail de l'employeur.
- **Statut et fiscalité** : valider avec l'URSSAF ou un expert-comptable le cadre d'activité (micro-entreprise ou autre) et la déclaration des revenus publicitaires.
- **Google Play :** compte développeur, fiche de l'app, formulaire **Sécurité des données (Data Safety)**, **classification du contenu**, déclaration de **publicité**, public cible (non destiné aux enfants), **politique de confidentialité** hébergée sur une URL publique.
- **Compte personnel récent :** test fermé obligatoire (12 testeurs, 14 jours continus) avant l'accès à la production. À re-vérifier dans l'aide Google Play au moment du lancement.
- **RGPD :** consentement pubs (UMP / CMP), mention dans la politique de confidentialité, aucune donnée personnelle superflue collectée.
- **Propriété intellectuelle :** nom du jeu et icône vérifiés (pas de marque existante), assets et sons sous licence valide.

---

## 10. Mesure et critères de décision

### 10.1 Événements à suivre (simples, respectueux de la vie privée)
Début de partie, fin de partie (score, niveau max, durée), pub récompensée vue, interstitiel affiché, achat "sans pub", défi quotidien lancé.

### 10.2 Indicateurs cibles (hypothèses de départ, **[À TESTER]**)
| Indicateur | Seuil "encourageant" |
|------------|----------------------|
| Parties par session | 3 ou plus |
| Durée moyenne de session | 3 à 6 minutes |
| Rétention J1 | 30 % ou plus |
| Rétention J7 | 8 à 10 % ou plus |
| Taux de crash | Aucun crash bloquant |

### 10.3 Critères d'arrêt / pivot
- Après le prototype : si moins de 3 testeurs sur 5 relancent une partie spontanément, **retravailler la mécanique** avant tout développement du reste.
- Après le lancement : si la rétention reste très basse malgré 2 itérations, **arrêter ou pivoter** plutôt que d'investir davantage.

---

## 11. Risques

| Risque | Impact | Parade |
|--------|--------|--------|
| Concept pas assez addictif | Élevé | Prototype testé tôt, critère d'arrêt |
| Stratégie dominante (toujours au centre) | Moyen | Leviers d'équilibrage section 4.5 |
| Marché puzzle saturé, peu de visibilité | Élevé | Niche (miroir), ASO, vidéos courtes, accepter un résultat modeste |
| Difficulté à recruter 12 testeurs | Moyen | Recruter dès la phase prototype (amis, collègues, communautés) |
| Plugins pubs / achats incompatibles | Moyen | Tester l'intégration tôt, avoir une alternative |
| Rejet Google Play (data safety, pubs, consentement) | Moyen | Check-list conformité avant soumission |
| Manque de temps | Moyen | Périmètre MVP strict, phases courtes, jalons |
| Conflit avec le contrat ESN | Élevé | Vérification dès la phase 0 |

---

## 12. Livrables

- Projet Godot versionné sous Git
- Build **AAB** signé, prêt pour Google Play
- Fiche store complète (textes FR / EN, icône, visuels, vidéo optionnelle)
- Politique de confidentialité en ligne
- Fichier d'équilibrage et documentation interne minimale
- `STEPS.md` : plan de réalisation pas à pas
