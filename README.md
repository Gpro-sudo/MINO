# MINO 🐱 — Le petit chat rétro

Mini-jeu de chat parlant inspiré de l'ambiance des premières applications mobiles de 2010.

**[Tester la dernière version privée](https://mino-retro-2010.kwmxworh2760802.chatgpt.site)**

> MINO est un personnage original, indépendant de Talking Tom et d'Outfit7.

## Version 0.2 — refonte visuelle

- Personnage au rendu 3D pré-calculé, avec textures de pelage, clignements et bouche animée.
- Ruelle en 3D pré-calculée.
- Réactions quand on touche la tête, le ventre, les pattes et la queue.
- Boutons Lait, Chatouille et Griffe.
- Répétition vocale plus aiguë (micro autorisé uniquement après action).
- Adapté à l'ordinateur et au téléphone, sans publicité ni compte.
- Les enregistrements restent dans ton navigateur.

Le jeu est toujours en **2D animée à partir d'images 3D**, pas encore un modèle 3D temps réel. C'est un prototype rapide pour valider le style et les interactions.

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
└── README.md
```

Aucune bibliothèque JavaScript n'est requise. Les sprites et le décor sont des images optimisées WebP.

## Ensuite

- Tester le microphone et l'animation de bouche sur plusieurs appareils.
- Ajouter davantage d'expressions, de poses et de sons originaux.
- Évaluer une vraie version 3D animée ou une application Android.

## Licence

Ce dépôt est public. Aucun droit de réutilisation n'est accordé par défaut au-delà de la consultation ; nous pourrons choisir une licence explicite plus tard.
