@echo off
setlocal EnableExtensions
REM MINO - Execute Stable Fast 3D sur la RTX 4060 sans serveur externe.
REM Avec un argument: generer_sf3d.cmd "D:\chemin\image_mino.png"
REM Sans argument: teste l'image chaise fournie par le depot officiel.
set "BASE=%~dp0"
set "PY=%BASE%.venv-sf3d\Scripts\python.exe"
set "SF3D=%BASE%stable-fast-3d"
set "MODEL=%BASE%models\stable-fast-3d"
set "CUDA_HOME=D:\pinokio\bin\miniforge\Library"
set "CUDA_PATH=%CUDA_HOME%"
set "PATH=%CUDA_HOME%\bin;%PATH%"

if not exist "%PY%" (
  echo ERREUR : environnement Python MINO absent.
  exit /b 1
)
if not exist "%SF3D%\run.py" (
  echo ERREUR : source officielle Stable Fast 3D absente.
  exit /b 2
)
if not exist "%MODEL%\config.yaml" (
  echo ERREUR : config.yaml absent.
  echo Lance telecharger_modele_sf3d.py apres le login Hugging Face.
  exit /b 3
)
if not exist "%MODEL%\model.safetensors" (
  echo ERREUR : model.safetensors absent.
  echo Lance telecharger_modele_sf3d.py apres le login Hugging Face.
  exit /b 4
)

if "%~1"=="" (
  set "IMAGE=%SF3D%\demo_files\examples\chair1.png"
  set "DEST=%BASE%output\test_chaise"
  echo Aucune image specifiee : essai sur chair1.png du projet officiel.
) else (
  set "IMAGE=%~f1"
  set "DEST=%BASE%output\mino"
)
if not exist "%IMAGE%" (
  echo ERREUR : image d entree inexistante : "%IMAGE%"
  exit /b 5
)
echo.
echo ============ MINO / GENERATION 3D LOCALE ============
echo Image : "%IMAGE%"
echo GPU : CUDA, NVIDIA RTX 4060
echo Modele : "%MODEL%"
echo Resultat : "%DEST%\0\mesh.glb"
echo.
echo Premier demarrage : rembg peut telecharger son propre modele de suppression du fond.
echo En cas de manque de memoire GPU, ferme les autres applications gourmandes.
echo.

"%PY%" -u "%SF3D%\run.py" "%IMAGE%" --device cuda --pretrained-model "%MODEL%" --output-dir "%DEST%" --texture-resolution 1024 --remesh_option none
if errorlevel 1 (
  echo.
  echo ECHEC generation : envoie-moi les dernieres lignes du message.
  exit /b 6
)
if not exist "%DEST%\0\mesh.glb" (
  echo ECHEC : conversion terminee mais fichier mesh.glb absent.
  exit /b 7
)
echo.
echo ========== SUCCES MINO : MODELE GLB CREE ==========
echo "%DEST%\0\mesh.glb"
echo Le fichier est local, dans output, et n est pas envoye sur GitHub.
exit /b 0
