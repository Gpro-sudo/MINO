# MINO 🐱 — Le petit chat rétro

Mini-jeu de chat parlant inspiré de l'ambiance des premières applications mobiles de 2010.


> MINO est un personnage original, indépendant de Talking Tom et d'Outfit7.

## Version 0.2 — refonte visuelle

- Personnage au rendu 3D pré-calculé, avec textures de pelage, clignements et bouche animée.
- Ruelle en 3D pré-calculée.
- Réactions quand on touche la tête, le ventre, les pattes et la queue.
- Boutons Lait, Chatouille et Griffe.
- Répétition vocale plus aiguë (micro autorisé uniquement après action).
- Adapté à l'ordinateur et au téléphone, sans publicité ni compte.
- Les enregistrements restent dans ton navigateur.

La version historique à la racine reste en **2D animée à partir d'images 3D**. La nouvelle expérience 3D temps réel est dans `3d/`.

## Installer dans ton dossier Windows

Si tu as déjà cloné le dépôt :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
py -m http.server 8000
```

Puis ouvre [http://localhost:8000](http://localhost:8000).

Si tu n'as pas encore cloné et que le dossier est vide :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git clone https://github.com/Gpro-sudo/MINO.git .
```

Pour le micro, utilise un serveur `localhost` ou un site HTTPS. La commande `py` nécessite Python.

## Fichiers

```text
MINO/
├── index.html          # Interface, interactions, animations et audio
├── assets/
│   ├── alley.webp      # Ruelle texturée
│   ├── mino-idle.webp  # Position normale
│   ├── mino-talk.webp  # Bouche ouverte
│   └── mino-blink.webp # Yeux fermés
├── 3d/                 # Version 0.3 WebGL temps réel
│   ├── index.html       # Interface 3D
│   ├── game.js          # Scène, interactions et voix
│   ├── mino-model.js    # Géométrie originale du chat
│   └── vendor/          # Three.js 0.180.0 + licence MIT
└── README.md
```

La version historique n'utilise pas de bibliothèque JavaScript. La version 3D utilise Three.js embarqué localement ; aucun CDN n'est nécessaire.

## Ensuite

- Tester le microphone et l'animation de bouche sur plusieurs appareils.
- Ajouter davantage d'expressions, de poses et de sons originaux.
- Améliorer les expressions et le squelette articulé de MINO 3D, puis évaluer une application Android.

## Licence

Ce dépôt est public. Aucun droit de réutilisation n'est accordé par défaut au-delà de la consultation ; nous pourrons choisir une licence explicite plus tard.

## MINO 0.5 — modèle Blender (intégration en cours)

Le jeu 3D dispose maintenant d'un chargeur glTF 2.0 natif via **Three.js GLTFLoader r180** (licence MIT). Le personnage Blender est importé depuis `3d/assets/mino_anim.glb`. Quand l'asset manque, la version procédurale 0.4 est conservée comme solution de secours.

**Sur Windows, après génération de `blender/mino_anim.glb` :**

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
py blender/prepare_game_asset.py
git add 3d/assets/mino_anim.glb
git commit -m "feat: add original Blender MINO character"
git push origin main
py -m http.server 8000
```

Ouvrir **http://localhost:8000/3d/**. Le script corrige les pivots du GLB exporté, sans modifier les maillages. Les huit pistes de mouvements Blender sont ensuite rejouées avec `THREE.AnimationMixer`, et les interactions fonctionnent par-dessus. C'est un modèle de départ contrôlé par des pivots, et **non un squelette de déformation**. Tester le comportement visuel sur le PC utilisateur avant déploiement final.

## MINO 0.4 — vraie 3D temps réel

Une scène WebGL indépendante est disponible dans [3d/](./3d/). Le modèle original de MINO évolue : une tête et des joues sculptées dans un maillage continu, des oreilles plus courtes, des yeux verts, des membres affinés et un pelage clair intégré à la géométrie, dans une petite ruelle. Les interactions et la voix sont préservées.
Elle utilise Three.js **0.180.0** (licence MIT dans `3d/vendor/`) et un chat en vraie géométrie 3D : tête, bras, pattes, queue, yeux et bouche sont animables séparément.

Après `git pull origin main` et `py -m http.server 8000` :

- Version historique : **http://localhost:8000/**
- Prototype 3D : **http://localhost:8000/3d/**

C'est une étape de création originale en 3D temps réel, pas encore un modèle 3D définitif. Les fichiers visuels de référence de Talking Tom ne sont pas inclus dans ce dépôt.
