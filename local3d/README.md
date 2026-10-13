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

## Etape 1 ter : reutiliser le nvcc CUDA 12.8 de Pinokio

La machine dispose deja de `D:\\pinokio\\bin\\miniforge\\Library\\bin\\nvcc.exe`, version 12.8.93.
Il n'est **pas utile** de reinstaller CUDA avant de verifier si les en-tetes et bibliotheques sont deja presents.

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\verifier_cuda_sf3d.ps1'
```

Le script ne modifie rien : il localise `nvcc`, teste `cuda_runtime.h`, `cuda.h`, les bibliotheques `cudart*.lib`, l'outil C++ Visual Studio et le `CUDA_HOME` detecte par PyTorch. Le pilote et les roues PyTorch fonctionnent deja. Attention : `nvcc 12.8` / PyTorch CUDA 12.1 est un decalage de version mineure, **pas une compatibilite de compilation garantie**. Les `setup.py` des extensions `texture_baker` et `uv_unwrapper` comportent des options Linux qui peuvent necessiter un correctif Windows.

## Etape 2 : installer Stable Fast 3D (compilation Windows)

Les derniers diagnostics confirment que le toolkit Conda de Pinokio possede `nvcc 12.8.93`, ses en-tetes, `Library/lib/cudart.lib` et `cudart_static.lib`. Le compilateur Microsoft Visual Studio 2022 est present. Les bibliotheques CUDA embarquees dans PyTorch sont en version 12.1, donc la compilation reste a valider.

Dans PowerShell :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
& '.\local3d\installer_sf3d.cmd'
```

Le script Windows :
1. active temporairement `vcvars64.bat`, `CUDA_HOME`, `LIB` et `INCLUDE` sans modifier la configuration Windows ni Pinokio ;
2. teste de nouveau PyTorch CUDA et clone les sources officielles sous `local3d/stable-fast-3d/` ;
3. adapte dans **cette copie locale uniquement** les options GCC des deux `setup.py` en options MSVC ;
4. epingle `numpy==1.26.4` et `setuptools==69.5.1`, installe les dependances et utilise `rembg` en mode CPU pour economiser la VRAM ;
5. tente de compiler `texture_baker` (CUDA) puis `uv_unwrapper` (C++) et verifie les imports.

Sous Windows, les deux compilations **restent experimentales**. En cas d'erreur, ne pas recreer l'environnement : partager le message affiche a l'etape en echec. Le script est relancable : il ne reclone pas automatiquement ni ne met a jour les sources existantes. Il **n'installe aucun pilote**, ne modifie pas Pinokio et ne telecharge pas encore les poids du modele.

Les fichiers volumineux restent ignores par `.gitignore`. L'acces au modele lui-meme exige une demande d'autorisation sur [Hugging Face](https://huggingface.co/stabilityai/stable-fast-3d) ; ne jamais publier de jeton prive.

## Etape 3 : autorisation du modele et premiere generation

- [Stable Fast 3D — documentation officielle](https://github.com/Stability-AI/stable-fast-3d)
- [Modele Hugging Face a acces controle](https://huggingface.co/stabilityai/stable-fast-3d)
- [Guide d'installation CUDA Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/)

Stable Fast 3D necessite des dependances Python et la bonne combinaison PyTorch/CUDA. L'installation Windows **reste experimentale** ; la documentation officielle estime environ 6 Gio de VRAM pour une image, ce qui laisse peu de marge sur une carte de 8 Gio. Verifier le CUDA Toolkit et le compilateur `nvcc` avant les extensions natives. Ne pas confondre la version CUDA affichee par `nvidia-smi` avec le CUDA Toolkit installe.

Le modele Hugging Face est a acces controle : il faudra demander son acces depuis le compte de l'utilisateur. Ne jamais enregistrer ni committer un jeton prive dans Git.

Le modele produit par l'IA ne disposera pas automatiquement des expressions faciales de MINO : les paupieres, la bouche et les mouvements d'oreilles resteront a travailler sous Blender.
