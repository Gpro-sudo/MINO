# MINO — Atelier Blender

Ce dossier accompagne la transition vers un modèle 3D original **éditable dans Blender**.

## Débuter sans connaissances 3D

1. Installer [Blender](https://www.blender.org/download/) (version 4.5 LTS ou ultérieure).
2. Télécharger le **kit MINO Blender** fourni dans la conversation et décompresser le dossier \`MINO_Blender\` dans le dépôt local.
3. Double-cliquer sur \`MINO_Blender/creer_mino.bat\`.
4. Ouvrir le fichier généré \`mino_rig.blend\` dans Blender et appuyer sur Espace pour visualiser les animations.

Le kit contient déjà \`mino_base.glb\` ainsi que les scripts \`generate_glb.py\`, \`build_mino.py\` et \`creer_mino.bat\`. Un script peut ainsi produire \`mino_rig.blend\` et \`mino_anim.glb\` sur Windows.

**État :** le fichier GLB initial a été généré et rechargé avec succès. L'exécution effective du script Blender et la conversion vers un véritable rig de qualité studio restent à tester. La version du jeu dans \`3d/\` n'a pas encore été remplacée.

Les références visuelles de Talking Tom servent seulement à définir une ambiance. MINO est un personnage indépendant.

## Versionnage Git

Une fois le kit décompressé dans le dépôt local :

\`\`\`powershell
cd 'D:\07-Logiciels\37-MINO'
git status
git add MINO_Blender
git commit -m "feat: add editable MINO Blender character starter"
git push origin main
\`\`\`

Ces commandes versionnent les scripts et l'asset dans TON dépôt, sans écraser les versions précédentes du jeu.
