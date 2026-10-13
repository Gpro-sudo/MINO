@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
set "BLENDER_EXE="
for /f "delims=" %%F in ('where blender 2^>nul') do if not defined BLENDER_EXE set "BLENDER_EXE=%%F"
if not defined BLENDER_EXE (
  for /d %%D in ("%ProgramFiles%\Blender Foundation\Blender *") do (
    if exist "%%~fD\blender.exe" set "BLENDER_EXE=%%~fD\blender.exe"
  )
)
if not defined BLENDER_EXE (
  echo Blender n'est pas encore installe ou introuvable.
  echo Telecharge le sur https://www.blender.org/download/
  echo Installe-le, puis relance ce fichier.
  pause
  exit /b 1
)
echo.
echo [MINO] Blender trouve : !BLENDER_EXE!
echo [MINO] Construction du projet Blender et export GLB...
"!BLENDER_EXE!" --background --factory-startup --python "%~dp0build_mino.py"
if errorlevel 1 (
  echo.
  echo La construction a rencontre une erreur. Envoie-moi le texte affiche ici.
  pause
  exit /b 1
)
echo.
echo Termine ! Ouvre mino_rig.blend avec Blender.
echo L'export mino_anim.glb est aussi disponible.
pause
