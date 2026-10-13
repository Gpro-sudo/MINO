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

Le lanceur cherche une version **Windows Installer classique** de Blender, ou une version portable placee dans `MINO/BlenderPortable`. Les fichiers `blender.exe` de la version Microsoft Store se trouvent dans `WindowsApps` et ne sont pas directement accessibles au script (erreur Windows `Access is denied`). Il faut donc utiliser l'installateur Windows de [blender.org](https://www.blender.org/download/) sans desinstaller la version Store. Il lance **build_mino.py** qui crée directement la géométrie à partir de Blender ; aucun fichier \`mino_base.glb\`, Python ou paquet extérieur n'est nécessaire.

### Résultats attendus

- **mino_rig.blend** : le personnage et sa scène modifiables dans Blender ;
- **mino_anim.glb** : export de base utilisable dans un moteur 3D ;
- des contrôleurs simples de la tête, des yeux, des bras et de la queue avec quelques mouvements de démonstration.

**Limitation connue :** ces contrôleurs sont des pivots d'objets, pas encore une armature de déformation professionnelle. La qualité finale du personnage reste à améliorer. L'exécution réelle sous Blender 5.2 doit être validée sur un PC utilisateur.

Si le programme s'arrête avec une erreur, renvoie la fin du message affiché dans la fenêtre noire. Ne relance pas le jeu WebGL avant d'avoir validé ce modèle.

## Nouvelle base Stable Fast 3D — etape 1 non destructive

Quand `local3d/output/mino/0/mesh.glb` a ete genere avec Stable Fast 3D, tu peux preparer une version Blender directement :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\blender\preparer_mino_sf3d.ps1'
```

Le lanceur retrouve Blender 5.2 installe sur D:, importe le GLB, renomme le maillage `MINO_SF3D_CORPS`, active un affichage du materiau, applique un lissage d'affichage et **integre les textures** dans le fichier `.blend`. Il cree `blender/mino_sf3d_base.blend`, ou un nouveau fichier numerote s'il existe deja. Il ne touche ni au modele d'origine ni au jeu MINO 0.5.

Ouvre le fichier genere dans Blender, observe le chat en couleur depuis l'avant, puis regarde son profil (pave numerique `3`). Envoyer des captures des deux vues pour decider comment separer les yeux et la bouche dans l'etape 2. **Il n'y a pas encore de squelette ni d'animation faciale.**
