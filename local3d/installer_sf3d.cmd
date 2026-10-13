@echo off
setlocal EnableExtensions
REM MINO - Install Stable Fast 3D in an isolated Python virtualenv (Windows).
REM Downloads official SF3D source and pip packages; builds local C++/CUDA extensions.
REM Does NOT install drivers/CUDA/VS or modify the Pinokio conda environment.
set "BASE=%~dp0"
set "PY=%BASE%.venv-sf3d\Scripts\python.exe"
set "SF3D=%BASE%stable-fast-3d"
set "CUDA_HOME=D:\pinokio\bin\miniforge\Library"
set "CUDA_PATH=%CUDA_HOME%"
set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

echo.
echo ============ MINO / INSTALLATION SF3D WINDOWS ============
if not exist "%PY%" (
  echo ERREUR: environnement Python introuvable.
  echo Lance preparer_sf3d.ps1 puis installer_pytorch_gpu.ps1.
  exit /b 1
)
if not exist "%CUDA_HOME%\bin\nvcc.exe" (
  echo ERREUR: compilateur CUDA de Pinokio introuvable.
  exit /b 2
)
if not exist "%CUDA_HOME%\lib\cudart_static.lib" (
  echo ERREUR: bibliotheque CUDA manquante.
  exit /b 3
)
if not exist "%VCVARS%" (
  echo ERREUR: outils Visual Studio 2022 x64 introuvables.
  exit /b 4
)
where git >nul 2>&1
if errorlevel 1 (
  echo ERREUR: git.exe introuvable dans le PATH.
  exit /b 5
)

echo.
echo [1/7] Initialisation du compilateur Microsoft C++ x64
call "%VCVARS%" >nul
if errorlevel 1 (
  echo ERREUR: activation de Visual Studio impossible.
  exit /b 6
)
where cl
set "DISTUTILS_USE_SDK=1"
set "MSSdk=1"
set "PATH=%CUDA_HOME%\bin;%CUDA_HOME%\lib;%PATH%"
set "LIB=%CUDA_HOME%\lib;%LIB%"
set "INCLUDE=%CUDA_HOME%\include;%INCLUDE%"
set "USE_NATIVE_ARCH=0"
set "TORCH_CUDA_ARCH_LIST=8.9"
set "MAX_JOBS=2"
set "USE_CUDA=1"
"%CUDA_HOME%\bin\nvcc.exe" --version
if errorlevel 1 exit /b 7

echo.
echo [2/7] Verification de PyTorch avec la RTX 4060
"%PY%" "%BASE%test_cuda.py"
if errorlevel 1 (
  echo ERREUR: test PyTorch CUDA en echec.
  exit /b 8
)

echo.
echo [3/7] Recuperation du code officiel Stable Fast 3D
if not exist "%SF3D%\run.py" (
  if exist "%SF3D%" (
    echo ERREUR: dossier SF3D existant mais incomplet. Aucun fichier supprime.
    exit /b 9
  )
  git clone --depth 1 https://github.com/Stability-AI/stable-fast-3d.git "%SF3D%"
  if errorlevel 1 exit /b 10
) else (
  echo Sources SF3D deja presentes. Aucune mise a jour automatique.
)

echo.
echo [4/7] Corrections des options GCC incompatibles avec Windows
"%PY%" "%BASE%patcher_sf3d_windows.py" "%SF3D%"
if errorlevel 1 exit /b 11

echo.
echo [5/7] Preparation des dependances Python compatibles
echo Installation dans : %PY%
"%PY%" -m pip install --disable-pip-version-check "numpy==1.26.4" "setuptools==69.5.1" "wheel" "ninja"
if errorlevel 1 exit /b 12
"%PY%" -m pip install --disable-pip-version-check -r "%SF3D%\_mino_requirements_windows.txt"
if errorlevel 1 (
  echo ERREUR: dependances Python. Copie les dernieres lignes d erreur.
  exit /b 13
)

echo.
echo [6/7] Compilation native texture_baker (CUDA / MSVC)
"%PY%" -m pip install --disable-pip-version-check --no-build-isolation --no-deps -v "%SF3D%\texture_baker"
if errorlevel 1 (
  echo ERREUR: compilation texture_baker. Copie les dernieres lignes d erreur.
  exit /b 14
)

echo.
echo [7/7] Compilation native uv_unwrapper (C++ / MSVC)
"%PY%" -m pip install --disable-pip-version-check --no-build-isolation --no-deps -v "%SF3D%\uv_unwrapper"
if errorlevel 1 (
  echo ERREUR: compilation uv_unwrapper. Copie les dernieres lignes d erreur.
  exit /b 15
)

echo.
echo Verification de l import des deux extensions...
"%PY%" -c "import texture_baker,uv_unwrapper; print('MINO SF3D: extensions installees')"
if errorlevel 1 (
  echo ATTENTION: compilation passee mais import des extensions impossible.
  exit /b 16
)

echo.
echo ========= MINO SF3D: DEPENDANCES INSTALLEES =========
echo Le modele IA n est pas encore telecharge.
echo Acces modele: https://huggingface.co/stabilityai/stable-fast-3d
echo Envoie-moi le resultat pour preparer la premiere generation MINO.
exit /b 0
