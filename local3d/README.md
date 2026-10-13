# MINO — generation 3D par IA en local (Windows)

Objectif : utiliser une image **originale de MINO** pour generer un \`.glb\`, puis terminer les expressions et animations dans Blender. Le site actuel MINO 0.5 et le moteur Three.js restent intacts.

## Configuration validee par le diagnostic

- NVIDIA GeForce RTX 4060 avec 8 Gio de VRAM (environ 7,1 Gio disponibles au repos)
- 31,8 Gio de RAM
- 271 Gio libres sur le disque D:
- Visual Studio 2022 avec outils C++
- CPython **3.11.15 x64 gere par uv**, disponible sous AppData/Roaming/uv/python mais **non resolu par \`py -3.11\`**
- \`nvcc\` absent du PATH : CUDA Toolkit non confirme

## Etape 1 : environnement Python isole

Dans PowerShell :

\`\`\`powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\preparer_sf3d.ps1'
\`\`\`

Le script retrouve le CPython 3.11 installe par \`uv\`, cree \`local3d/.venv-sf3d/\` et verifie les executable. Il **n'installe pas Stable Fast 3D, PyTorch, CUDA ou les poids du modele**. L'environnement est ignore par Git.

## Etape 2 (a preparer apres le retour du script)

- [Stable Fast 3D — documentation officielle](https://github.com/Stability-AI/stable-fast-3d)
- [Modele Hugging Face a acces controle](https://huggingface.co/stabilityai/stable-fast-3d)
- [Guide d'installation CUDA Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/)

Stable Fast 3D necessite des dependances Python et la bonne combinaison PyTorch/CUDA. L'installation Windows **reste experimentale** ; la documentation officielle estime environ 6 Gio de VRAM pour une image, ce qui laisse peu de marge sur une carte de 8 Gio. Verifier le CUDA Toolkit et le compilateur \`nvcc\` avant les extensions natives. Ne pas confondre la version CUDA affichee par \`nvidia-smi\` avec le CUDA Toolkit installe.

Le modele Hugging Face est a acces controle : il faudra demander son acces depuis le compte de l'utilisateur. Ne jamais enregistrer ni committer un jeton prive dans Git.

Le modele produit par l'IA ne disposera pas automatiquement des expressions faciales de MINO : les paupieres, la bouche et les mouvements d'oreilles resteront a travailler sous Blender.
