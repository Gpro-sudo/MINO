# MINO 🐱 — Le petit chat rétro

Un mini-jeu de chat parlant pour retrouver le charme des premières applications mobiles de 2010.

**[Essayer le prototype privé](https://mino-retro-2010.kwmxworh2760802.chatgpt.site)**

> Projet indépendant : MINO est un personnage original, non affilié à Talking Tom ou Outfit7.

## Fonctionnalités — version 0.1

- Chat interactif dessiné en SVG avec animations.
- Réactions au toucher de la tête, du ventre, des pattes et de la queue.
- Boutons **Lait**, **Chatouille** et **Griffe**.
- Enregistrement au micro d'une courte phrase, puis répétition en voix aiguë.
- Interface adaptée au mobile et à l'ordinateur.
- Aucun compte, aucune publicité, aucun envoi de la voix vers un serveur.

## Installation sur Windows

Si ton dossier `D:\07-Logiciels\37-MINO` est **vide**, ouvre PowerShell :

```powershell
Set-Location 'D:\07-Logiciels\37-MINO'
git clone https://github.com/Gpro-sudo/MINO.git .
```

Puis démarre un serveur local (Python requis) :

```powershell
py -m http.server 8000
```

Ouvre **http://localhost:8000** dans Chrome ou Edge, puis autorise le micro lorsque le jeu le demande.

Si ton dossier contient déjà des fichiers, vérifie-les avant de cloner : la commande ci-dessus nécessite un dossier vide.

Tu peux ouvrir `index.html` directement pour voir les animations, mais le micro fonctionne mieux sur `localhost` ou HTTPS.

## Structure

```text
MINO/
├── index.html    # Tout le prototype : interface, SVG, animations et sons
└── README.md     # Ce guide
```

Aucune dépendance n'est nécessaire pour cette première version.

## Suite du projet

1. Tester le micro sur Android, iPhone et PC.
2. Améliorer les animations et les expressions.
3. Ajouter des sons originaux et des interactions surprises.
4. Envisager une application Android installable (APK).

## Licence

Ce dépôt est public. Le code et les graphismes constituent un prototype de travail ; aucune licence de réutilisation n'est accordée par défaut.
