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

Les derniers diagnostics confirment que le toolkit Conda de Pinokio possede `nvcc 12.8.93`, ses en-tetes, `Library/lib/cudart.lib` et `cudart_static.lib`. Le compilateur Microsoft Visual Studio 2022 est present. Les bibliotheques CUDA embarquees dans PyTorch sont en version 12.1. Le 13 octobre 2026, les deux extensions natives ont ete compilees et importees avec succes sur la RTX 4060 Windows.

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

## Etape 3 : verifier le moteur SANS poids IA

La compilation native de `texture_baker` et `uv_unwrapper` est maintenant **reussie** sur ce PC. Avant de telecharger les poids controles par Hugging Face, verifier que le moteur Python complet s'importe :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
& '.\local3d\.venv-sf3d\Scripts\python.exe' '.\local3d\test_sf3d_runtime.py'
```

Resultat vise : `MINO SF3D : TEST D IMPORT REUSSI`. Ce test ne telecharge rien.

## Etape 4 : recuperer les poids autorises sur Hugging Face

1. Se connecter au site [Hugging Face](https://huggingface.co/stabilityai/stable-fast-3d), demander et obtenir l'acces aux poids du modele.
2. Creer si necessaire un [jeton personnel en lecture](https://huggingface.co/settings/tokens), uniquement depuis le site Hugging Face.
3. Authentifier **localement** le Python MINO :

```powershell
& '.\local3d\.venv-sf3d\Scripts\huggingface-cli.exe' login
```

Saisir le token directement dans PowerShell (il peut ne pas s'afficher pendant la saisie). Si une question demande d'enregistrer le token dans Git, repondre non : ce n'est pas necessaire pour telecharger le modele. **Ne jamais copier le jeton dans GitHub ni dans la conversation.**

Ensuite :

```powershell
& '.\local3d\.venv-sf3d\Scripts\python.exe' '.\local3d\telecharger_modele_sf3d.py'
```

Le script telecharge `config.yaml` et `model.safetensors` dans le dossier ignore par Git `local3d/models/stable-fast-3d/` et ne journalise aucun jeton. L'acces peut rester en attente ou etre refuse par le fournisseur ; la compilation locale ne donne pas automatiquement acces aux poids.

## Etape 5 : premiere generation 3D locale (sans modifier le jeu MINO)

Essai avec la photo de chaise fournie dans le depot officiel :

```powershell
& '.\local3d\generer_sf3d.cmd'
```

Si la generation reussit, ouvrir `local3d/output/test_chaise/0/mesh.glb` dans Blender.

### Choix de l'image originale de MINO

Le meilleur point de depart est **`assets/mino-idle.webp`** : le chat entier, de face, les yeux verts ouverts, la bouche fermee et le fond transparent. Les variantes `mino-blink.webp` et `mino-talk.webp` sont moins adaptees : une pose de visage anime pourrait etre incorporee au maillage 3D. Les captures du jeu incluent trop de decor.

Un script prepare automatiquement cette image depuis le depot et la met au bon format sans changer le personnage :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
& '.\local3d\.venv-sf3d\Scripts\python.exe' '.\local3d\preparer_reference_mino.py'
```

Il cree `local3d/inputs/mino_reference.png` (1024 x 1024, RGBA, fond transparent, proportions conservees). Le source original reste intact, et le PNG genere est ignore par Git.

Lancer ensuite la premiere conversion de MINO :

```powershell
& '.\local3d\generer_sf3d.cmd' '.\local3d\inputs\mino_reference.png'
```

Le resultat se trouve dans `local3d/output/mino/0/mesh.glb`. Ne pas remplacer automatiquement `3d/assets/mino_anim.glb` : l'export brut **n'a ni squelette ni animation faciale**. Il faut d'abord le verifier et l'adapter dans Blender. A la premiere conversion, `rembg` peut telecharger son propre petit modele de suppression du fond ; un acces internet est donc requis pour l'installation initiale et le premier passage. Les executions suivantes peuvent rester locales quand tous les fichiers sont presents.


## Etape TRELLIS — preparer un laboratoire sans modifier ComfyUI Pinokio

ComfyUI Pinokio detecte sous `D:\pinokio\api\comfy.git\app` :
- Python 3.10.20, PyTorch 2.7.0+cu128 ;
- RTX 4060, 8 Go VRAM (environ 7,25 Go disponibles lors du test).

Le module communautaire [ComfTrellis](https://github.com/Scaryplasmon/ComfTrellis) annonce 8 Go de VRAM mais son `requirements.txt` fait reference a CUDA 12.4 / PyTorch 2.5.1. Son `__init__.py` **lance automatiquement** `setup.py` pour les modules absents ; ce script peut faire intervenir pip et alterer les dependances du ComfyUI dans lequel il est installe. **Ne pas l'installer directement via ComfyUI Manager dans Pinokio**.

Avant toute installation des dependances, preparer deux copies du code et un environnement virtuel distinct :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\preparer_trellis_isole.ps1'
```

Ce script ne demarre pas ComfyUI, ne charge pas TRELLIS, ne telecharge pas de poids IA et **n'installe ni CUDA ni PyTorch**. Il cree uniquement `local3d/trellis_lab/ComfyUI`, y clone `ComfTrellis` comme noeud, et cree `.venv` Python 3.10 independant de Pinokio. Tout est ignore par Git. Il est prudent de ne pas demarrer cette copie tant que les dependances n'ont pas ete installees/validees explicitement.

Ensuite : installer des versions compatibles PyTorch/CUDA et roues d'extensions dans le laboratoire seulement, puis tester l'import et la memoire avant de creer le premier GLB avec `local3d/inputs/mino_reference.png`. La compatibilite 8 Go reste une annonce communautaire, pas une validation sur ce PC.

### TRELLIS : installer le GPU UNIQUEMENT dans le laboratoire

Le diagnostic Pinokio valide Python 3.10.20, mais ComfyUI utilise PyTorch 2.7.0+cu128. Ne pas lancer ni installer le noeud communautaire dans ce ComfyUI. ComfTrellis depend d'extensions prevues pour PyTorch 2.5.1 + CUDA 12.4 ; la documentation officielle PyTorch associe 2.5.1 a torchvision 0.20.1. xformers 0.0.28.post3 fournit une roue Windows cp310 pour CUDA 12.4.

Une fois `local3d/trellis_lab/.venv` prepare, utiliser :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\installer_trellis_torch.ps1'
```

Ce script installe `numpy==1.26.4`, `torch==2.5.1`, `torchvision==0.20.1` et `xformers==0.0.28.post3` **dans le venv du laboratoire seulement**. Il teste CUDA sur la RTX 4060 avec une multiplication de tenseurs et une operation `xformers.ops.memory_efficient_attention`. Il ne demarre pas TRELLIS et ne change rien dans `D:\pinokio\api\comfy.git\app`.

Attendre le message `MINO TRELLIS : PYTORCH ET XFORMERS GPU OPERATIONNELS`. Les extensions Kaolin, Spconv, nvdiffrast, vox2seq, etc., et les poids TRELLIS restent a installer/valider plus tard. Si l'installation echoue, conserver le venv et transmettre les messages d'erreur ; ne pas reinstalller ComfyUI.

### TRELLIS : dependances de base Kaolin et SpConv (etape suivante)

Apres le succes de `installer_trellis_torch.ps1`, ne **pas** installer ComfTrellis depuis le Manager de Pinokio. Le code du noeud communautaire lance un `setup.py` automatiquement quand il manque des paquets, et cette copie referencerait des roues CUDA de versions differentes. Le laboratoire TRELLIS est isole : le script suivant neutralise cet auto-installateur dans sa seule copie locale, puis installe explicitement les dependances.

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\installer_trellis_bibliotheques.ps1'
```

Il protege avec des contraintes `torch==2.5.1+cu124`, `torchvision==0.20.1+cu124`, `xformers==0.0.28.post3`, `numpy==1.26.4`. Il installe Kaolin 0.17.0 depuis les roues NVIDIA prevues pour PyTorch 2.5.1/CUDA 12.4 et SpConv `spconv-cu124`, ainsi que les bibliotheques Python de manipulation 3D et de traitement d'image. `rembg` utilise une installation ONNX CPU plutot que de consommer inutilement la VRAM de 8 Go pour supprimer le fond.

Resultat attendu : `MINO TRELLIS : BIBLIOTHEQUES DE BASE DISPONIBLES`. Ces composants ne suffisent pas encore a demarrer TRELLIS : il reste plusieurs extensions precompilees CUDA, la compatibilite avec ComfyUI, puis les poids du modele. Ne pas encore demarrer `trellis_lab/ComfyUI`.

### TRELLIS : extensions natives Windows (roues precompilees)

Quand `installer_trellis_bibliotheques.ps1` affiche `MINO TRELLIS : BIBLIOTHEQUES DE BASE DISPONIBLES`, il reste cinq extensions Windows a installer : `diff_gaussian_rasterization`, `diffoctreerast`, `utils3d`, `nvdiffrast`, `vox2seq`.

La copie du depot communautaire ComfTrellis contient deja les trois premieres roues (`wheels/...`). Les deux dernieres sont recuperees depuis les roues Windows Python 3.10 / PyTorch 2.5.1 / CUDA 12.4 du depot [MrForExample/Comfy3D_Pre_Builds](https://github.com/MrForExample/Comfy3D_Pre_Builds), utilise par l'installateur ComfTrellis lui-meme. Ce sont **des binaires communautaires tiers**, pas des composants verifies officiellement par Microsoft ou NVIDIA. Le script controle les tailles et l'integrite ZIP, mais ne peut pas auditer le code compile.

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\installer_trellis_extensions.ps1'
```

Le script teste d'abord PyTorch + xformers sur GPU, telecharge/verifie les deux wheels dans `local3d/trellis_lab/wheels/`, installe les 5 archives avec `pip --no-index --no-deps` (donc aucun remplacement de PyTorch), puis tente les imports natifs. Il **ne demarre pas ComfyUI**, ne modifie pas Pinokio et ne telecharge pas le modele IA.

Si `MINO TRELLIS : EXTENSIONS NATIVES CHARGEES` s'affiche, les imports sont valides, mais **les noyaux natifs en execution, le demarrage de ComfyUI et les besoins reels en VRAM ne le sont pas encore**. En cas d'echec, renvoyer les lignes `ECHEC` du terminal et conserver le laboratoire en l'etat.

#### Correction faux echec utils3d.__version__

Sur certaines versions de `utils3d` fournies dans le noeud ComfTrellis, le paquet ne declare pas l'attribut `__version__`. Son `__getattr__` dynamique essaie de charger `utils3d.__version__` au lieu de simplement retourner un attribut absent. L'ancien test utilisait `getattr(mod, '__version__', '')`, ce qui declenchait `ModuleNotFoundError: No module named 'utils3d.__version__'` bien que l'import du paquet ait reussi. Le test actuel emploie `vars(mod).get('__version__', '')`, qui n'execute pas `__getattr__`, et essaie egalement d'importer le sous-module `utils3d.torch` exploite par TRELLIS.

Dans ce cas precis, **ne pas relancer l'installation de toutes les roues**. Mettre a jour MINO, puis effectuer uniquement le test :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
& '.\local3d\trellis_lab\.venv\Scripts\python.exe' '.\local3d\test_trellis_extensions.py'
```

Si le test valide tous les imports, preparer ensuite le ComfyUI isole ; sinon conserver les lignes `ECHEC` pour rechercher la dependance exacte.

### ComfyUI TRELLIS isole : installer le serveur (Python 3.10 / torch 2.5.1 CUDA 12.4)

Quand `test_trellis_extensions.py` affiche `MINO TRELLIS : EXTENSIONS NATIVES CHARGEES`, le noeud reste pret cote bibliotheques mais le serveur ComfyUI manque encore. Le ComfyUI telecharge initialement depuis la branche recente ne convient pas necessairement aux anciennes extensions (2025). `installer_comfyui_trellis.ps1` selectionne **ComfyUI v0.3.31** dans le depot local ignore `local3d/trellis_lab/ComfyUI`, sans modifier les fichiers de Pinokio. Si cette copie contient deja des modifications Git suivies, la commande s'arrete plutot que de les ecraser.

Avant installation, le script verifie que l'auto-installateur ComfTrellis a bien ete neutralise dans le laboratoire et reteste PyTorch/xformers et les extensions natives. Il installe **torchaudio 2.5.1+cu124**, fixe `transformers==4.48.3` et `huggingface-hub==0.34.4` pour rester compatibles avec cette generation de ComfyUI et installer toutes ses dependances. Un fichier de contraintes bloque toute mise a niveau de `torch==2.5.1+cu124`, `torchvision==0.20.1+cu124`, `xformers==0.0.28.post3` et `numpy==1.26.4`.

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\installer_comfyui_trellis.ps1'
```

Si `MINO TRELLIS : COMFYUI ISOLE PRET POUR DEMARRAGE` apparait, alors seulement lancer **le ComfyUI isole sur le port 8189**, different du port 8188 de Pinokio :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\lancer_comfyui_trellis.ps1'
```

Dans le navigateur : `http://127.0.0.1:8189` (acces local uniquement). Ne pas lancer cette commande avant que les dependances soient verifiees, et en cas d'erreur conserver les dernieres lignes de la console. La presence des noeuds ComfTrellis reste a confirmer par le journal de lancement, et le modele `JeffreyXiang/TRELLIS-image-large` n'est pas encore telecharge.

#### Correctif : erreur Git `No names found, cannot describe anything`

Sur un clone superficiel (`git clone --depth 1`) de ComfyUI, la commande `git describe --tags --exact-match HEAD` pouvait echouer si le clone ne contenait pas d'etiquettes Git. PowerShell traitait ce message Git comme une erreur fatale avec `$ErrorActionPreference = 'Stop'`. Il s'agissait d'une erreur du script, et non du GPU ni de TRELLIS.

Le script corrige emploie `git tag --points-at HEAD`, qui reussit silencieusement sans etiquette, puis recupere le tag `v0.3.31` au besoin. Aucun paquet n'avait ete installe par la commande echouee : relancer simplement `git pull origin main`, puis `installer_comfyui_trellis.ps1`.

### ComfyUI TRELLIS : confirmer les noeuds live avant de telecharger les poids

Une fois le ComfyUI isole lance sur `http://127.0.0.1:8189` et la categorie `ComfTrellis` visible dans le navigateur, garder son terminal de lancement ouvert. L'interface seule ne prouve pas que toutes les classes de noeuds sont disponibles. Le script `verifier_noeuds_trellis.ps1` interroge l'API locale `/object_info` pour confirmer `LoadTrellisModel`, `TrellisInference`, `SaveGLBFile`, `RembgSquare` et `TrellisGrid` et afficher leurs champs requis.

Il copie sans ecraser l'illustration deja preparee `local3d/inputs/mino_reference.png` vers le dossier d'entree isole `local3d/trellis_lab/ComfyUI/input/MINO_reference.png` si elle existe, et affiche l'espace disponible sur le disque. Aucun poids TRELLIS n'est telecharge, aucun noeud n'est execute.

Dans une **deuxieme** fenetre PowerShell :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\verifier_noeuds_trellis.ps1'
```

Resultat espere : `MINO TRELLIS : TOUS LES NOEUDS PRESENTS`. Si une entree manque, verifier le journal du terminal de lancement ComfyUI pour la premiere erreur de chargement du noeud avant d'aller plus loin. Conserver la fenetre du serveur ouverte pour les etapes ulterieures.

### Correction de l'export GLB : `Ninja is required to load C++ extensions`

Le noeud SaveGLBFile de ComfTrellis utilise des bibliotheques qui compilent des extensions C++/CUDA a la volee. Quand ComfyUI TRELLIS est lance via `.venv/Scripts/python.exe` sans activation du venv, le dossier `.venv/Scripts` n'est pas necessairement dans la variable PATH, meme si pip a installe `ninja==1.13.2`. Les imports des extensions peuvent reussir puis l'export GLB echouer faute de `ninja.exe` dans PATH.

Le lanceur `lancer_comfyui_trellis.ps1` a ete corrige : il ajoute le dossier Scripts du venv et le chemin expose par `ninja.BIN_DIR` dans le PATH, verifie l'executable avec `ninja.exe --version`, et affiche des informations non bloquantes si `nvcc.exe` (compilateur CUDA) ou `cl.exe` (Visual Studio C++) ne sont pas presents. Le PATH est modifie uniquement dans le processus PowerShell qui lance ComfyUI et dans ses enfants ; Pinokio n'est pas touche.

Etapes en cas d'export impossible : enregistrer d'abord le workflow depuis l'interface ComfyUI, arreter proprement le serveur avec Ctrl+C dans son terminal, puis dans ce terminal :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\lancer_comfyui_trellis.ps1'
```

Confirmer l'affichage de `Ninja : ...\ninja.exe` et de sa version avant de relancer le workflow. Le modele TRELLIS deja telecharge sur disque ne devrait pas etre retelcharge, mais l'inference devra eventuellement etre relancee. Si une nouvelle erreur C++ ou CUDA survient, joindre le journal du terminal ; ne pas installer de composants systeme a l'aveugle.

### Export TRELLIS GLB : erreur de compilation `nvdiffrast_plugin`

Si l'aperçu 3D fonctionne mais `SaveGLBFile` affiche `Error building extension 'nvdiffrast_plugin'` apres que Ninja a ete trouve, l'inference a deja fonctionne et il reste un probleme de compilation des plugins C++/CUDA nvdiffrast pour l'export. Ne pas reinstaller les poids ni le venv.

La sortie visible peut se limiter aux commandes de compilation (`[1/16] cl`, `[3/16] nvcc`) et ne montre pas encore la cause (`fatal error`, `error Cxxxx`, `nvcc fatal`, etc.). Il faut conserver les **dernieres lignes completes** du rapport d'erreur ComfyUI ou de la fenetre du serveur. Le compilateur CUDA indique dans ce cas le repertoire `D:\pinokio\bin\miniforge\Library\bin` ; verifier sa vraie version plutot que de deduire une incompatibilite.

Dans un **deuxieme** PowerShell, le diagnostic suivant est en lecture seule et n'effectue aucune compilation :

```powershell
cd 'D:\07-Logiciels\37-MINO'
git pull origin main
powershell -NoProfile -ExecutionPolicy Bypass -File '.\local3d\diagnostic_compilation_glb.ps1'
```

Transmettre le resultat et les 30-50 dernieres lignes de l'erreur de `SaveGLBFile`. Le diagnostic affiche les chemins `ninja.exe`, `nvcc.exe`, `cl.exe`, la version nvcc, les variables CUDA et le `CUDA_HOME` que voit PyTorch 2.5.1+cu124. Selon le message precis, il faudra corriger les outils systeme detectes, pas le modele 3D.
