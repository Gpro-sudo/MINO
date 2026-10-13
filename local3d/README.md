# MINO — generation 3D par IA en local (Windows)

Objectif : utiliser une image **originale de MINO** pour generer un `.glb`, puis terminer les expressions et animations dans Blender. Le site actuel MINO 0.5 et le moteur Three.js restent intacts.

## Configuration validee par le diagnostic

- NVIDIA GeForce RTX 4060 avec 8 Gio de VRAM (environ 7,1 Gio disponibles au repos)
- 31,8 Gio de RAM
- 271 Gio libres sur le disque D:
- Visual Studio 2022 avec outils C++
- CPython **3.11.15 x64 gere par uv**, disponible sous AppData/Roaming/uv/python mais **non resolu par `py -3.11`**
- `nvcc` absent du PATH : CUDA Toolkit non confirme

## Etape 1 : environnement Python isole

Dans PowerShell :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\preparer_sf3d.ps1'
```

Le script retrouve le CPython 3.11 installe par `uv`, cree `local3d/.venv-sf3d/` et verifie les executable. Il **n'installe pas Stable Fast 3D, PyTorch, CUDA ou les poids du modele**. L'environnement est ignore par Git.

## Etape 1 bis : installer PyTorch CUDA et verifier la RTX 4060

Une fois `.venv-sf3d` cree, installer les roues officielles **PyTorch 2.4.1 / torchvision 0.19.1, CUDA 12.1** et lancer un calcul GPU :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\installer_pytorch_gpu.ps1'
```

Cette commande installe PyTorch uniquement dans `local3d/.venv-sf3d` et execute `test_cuda.py`, qui doit afficher `MINO CUDA : TEST REUSSI`. Le telechargement est volumineux. **Il ne faut pas installer le CUDA Toolkit avant de connaitre le resultat.** Le pilote NVIDIA moderne peut executer des roues PyTorch CUDA 12.1 sans Toolkit systeme ; le Toolkit sera eventuellement necessaire lors de la compilation d'extensions SF3D.

Si le test echoue, transmettre les dernieres lignes, sans rien reinstaller a l'aveugle.

## Etape 2 (a preparer apres le retour du script)

- [Stable Fast 3D — documentation officielle](https://github.com/Stability-AI/stable-fast-3d)
- [Modele Hugging Face a acces controle](https://huggingface.co/stabilityai/stable-fast-3d)
- [Guide d'installation CUDA Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/)

Stable Fast 3D necessite des dependances Python et la bonne combinaison PyTorch/CUDA. L'installation Windows **reste experimentale** ; la documentation officielle estime environ 6 Gio de VRAM pour une image, ce qui laisse peu de marge sur une carte de 8 Gio. Verifier le CUDA Toolkit et le compilateur `nvcc` avant les extensions natives. Ne pas confondre la version CUDA affichee par `nvidia-smi` avec le CUDA Toolkit installe.

Le modele Hugging Face est a acces controle : il faudra demander son acces depuis le compte de l'utilisateur. Ne jamais enregistrer ni committer un jeton prive dans Git.

Le modele produit par l'IA ne disposera pas automatiquement des expressions faciales de MINO : les paupieres, la bouche et les mouvements d'oreilles resteront a travailler sous Blender.
