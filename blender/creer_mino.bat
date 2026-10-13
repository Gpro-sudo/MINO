@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
if not exist "%~dp0lancer_mino.ps1" (
  echo [MINO] Fichier lancer_mino.ps1 manquant. Extrais le kit complet.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lancer_mino.ps1"
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" (
  echo.
  echo [MINO] Une erreur s'est produite. Envoie-moi le message affiche ci-dessus.
) else (
  echo.
  echo [MINO] Le projet Blender est pret.
)
pause
exit /b %RESULT%
