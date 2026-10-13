# MINO - Lancer ComfyUI isole pour TRELLIS sur le port 8189.
# Ce script ne s'execute qu'apres installation et validation des dependances.
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$comfy = Join-Path $base 'trellis_lab\ComfyUI'
$python = Join-Path $base 'trellis_lab\.venv\Scripts\python.exe'
$nodeInit = Join-Path $comfy 'custom_nodes\ComfTrellis\__init__.py'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw 'Python TRELLIS isole introuvable.' }
if (-not (Test-Path -LiteralPath (Join-Path $comfy 'main.py') -PathType Leaf)) { throw 'ComfyUI TRELLIS isole introuvable.' }
if (-not (Test-Path -LiteralPath $nodeInit -PathType Leaf)) { throw 'Noeud TRELLIS introuvable.' }
if (-not (Get-Content -LiteralPath $nodeInit -Raw).Contains('MINO LAB ONLY: installation automatique desactivee.')) {
    throw 'Auto-installation TRELLIS non neutralisee. Ne pas demarrer.'
}
Write-Host ''
Write-Host '========== MINO : COMFYUI TRELLIS ISOLE ==========' -ForegroundColor Cyan
Write-Host 'Adresse : http://127.0.0.1:8189' -ForegroundColor Green
Write-Host 'Arret : Ctrl+C dans cette fenetre PowerShell.'
Write-Host 'Port distinct du ComfyUI Pinokio (habituellement 8188).'
Write-Host 'Ne modifie ni Pinokio ni Stable Fast 3D.'
Write-Host ''
# Le venv est appele sans activation PowerShell. Or, torch.utils.cpp_extension
# cherche ninja.exe dans PATH, notamment pour SaveGLBFile / nvdiffrast.
$venvScripts = Split-Path -Path $python -Parent
$env:PATH = "$venvScripts;$env:PATH"
$ninjaBin = ''
$ninjaBinOutput = @(& $python -c 'import ninja; print(ninja.BIN_DIR)')
if ($LASTEXITCODE -ne 0) {
    throw "Le module ninja n est pas disponible dans le venv TRELLIS. Controle l installation de ninja."
}
if ($ninjaBinOutput.Count -gt 0) { $ninjaBin = "$($ninjaBinOutput[-1])".Trim() }
if (-not (Test-Path -LiteralPath (Join-Path $ninjaBin 'ninja.exe') -PathType Leaf)) {
    throw "ninja.exe introuvable dans le paquet Python ninja : $ninjaBin"
}
$env:PATH = "$ninjaBin;$env:PATH"
Write-Host ('Ninja : ' + (Join-Path $ninjaBin 'ninja.exe')) -ForegroundColor Green
& ninja.exe --version
if ($LASTEXITCODE -ne 0) { throw 'ninja.exe est present mais ne demarre pas.' }
# D'autres compilateurs peuvent etre necessaires apres Ninja.
if (-not (Get-Command nvcc.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'INFO : nvcc.exe absent du PATH. Un compilateur CUDA peut etre requis pour l export GLB.' -ForegroundColor Yellow
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'INFO : cl.exe absent du PATH. MSVC peut etre requis pour compiler les extensions C++.' -ForegroundColor Yellow
}
$env:ATTN_BACKEND = 'xformers'
$env:SPCONV_ALGO = 'native'
Push-Location -LiteralPath $comfy
try {
    & $python -u '.\main.py' --listen '127.0.0.1' --port 8189 --disable-auto-launch
    if ($LASTEXITCODE -ne 0) {
        Write-Host ('ComfyUI TRELLIS arrete sur une erreur : ' + $LASTEXITCODE) -ForegroundColor Red
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
