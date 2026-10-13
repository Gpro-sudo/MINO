# MINO — atelier Blender

Ce dossier est **autonome**. Il n'est plus nécessaire de télécharger ni de décompresser le kit ZIP séparé.

## Première exécution (Windows)

1. Installer Blender (déjà fait si tu suis cette conversation).
2. Ouvrir PowerShell puis saisir :

   ```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
cd blender
.\creer_mino.bat
```

3. Patienter pendant la génération du modèle, puis ouvrir **mino_rig.blend** dans Blender.

Le lanceur recherche automatiquement Blender, notamment l'installation Microsoft Store dans WindowsApps. Il lance **build_mino.py** qui crée directement la géométrie à partir de Blender ; aucun fichier \`mino_base.glb\`, Python ou paquet extérieur n'est nécessaire.

### Résultats attendus

- **mino_rig.blend** : le personnage et sa scène modifiables dans Blender ;
- **mino_anim.glb** : export de base utilisable dans un moteur 3D ;
- des contrôleurs simples de la tête, des yeux, des bras et de la queue avec quelques mouvements de démonstration.

**Limitation connue :** ces contrôleurs sont des pivots d'objets, pas encore une armature de déformation professionnelle. La qualité finale du personnage reste à améliorer. L'exécution réelle sous Blender 5.2 doit être validée sur un PC utilisateur.

Si le programme s'arrête avec une erreur, renvoie la fin du message affiché dans la fenêtre noire. Ne relance pas le jeu WebGL avant d'avoir validé ce modèle.
