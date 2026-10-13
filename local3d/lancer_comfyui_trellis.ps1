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
# LNK1181 cudart.lib : conda installe cudart.lib dans Library\lib,
# mais nvdiffrast cherche souvent Library\lib\x64.
# Le linker MSVC consulte aussi la variable LIB : on la complete SANS
# copier le fichier ni modifier CUDA ou le PATH systeme Windows.
$cudaRoots = @(
    'D:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4'
    'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4'
    $env:CUDA_HOME
    $env:CUDA_PATH
    'D:\pinokio\bin\miniforge\Library'
) | Where-Object { $_ } | Select-Object -Unique
$selectedCuda = $null
$selectedLib = $null
foreach ($candidate in $cudaRoots) {
    $nvccCandidate = Join-Path $candidate 'bin\nvcc.exe'
    if (-not (Test-Path -LiteralPath $nvccCandidate -PathType Leaf)) { continue }
    foreach ($subdir in @('lib\x64', 'lib')) {
        $libCandidate = Join-Path $candidate $subdir
        if (Test-Path -LiteralPath (Join-Path $libCandidate 'cudart.lib') -PathType Leaf) {
            $selectedCuda = $candidate
            $selectedLib = $libCandidate
            break
        }
    }
    if ($selectedCuda) { break }
}
if (-not $selectedCuda) {
    throw 'Compilateur CUDA et cudart.lib introuvables ensemble. Utilise diagnostic_compilation_glb.ps1.'
}
$env:CUDA_HOME = $selectedCuda
$env:CUDA_PATH = $selectedCuda
$env:PATH = "$(Join-Path $selectedCuda 'bin');$env:PATH"
if ($env:LIB) { $env:LIB = "$selectedLib;$env:LIB" } else { $env:LIB = $selectedLib }
Write-Host ('CUDA_HOME : ' + $env:CUDA_HOME) -ForegroundColor Cyan
Write-Host ('Bibliotheque cudart.lib : ' + (Join-Path $selectedLib 'cudart.lib')) -ForegroundColor Green
Write-Host ('LIB (ajout en tete) : ' + $selectedLib) -ForegroundColor Green
Write-Host 'Version du compilateur CUDA :'
& nvcc.exe --version
if ($LASTEXITCODE -ne 0) { throw 'nvcc.exe ne demarre pas.' }
if ($selectedCuda -match '(?i)miniforge') {
    Write-Host 'ATTENTION : nvcc de Pinokio est en CUDA 12.8 et PyTorch du labo en CUDA 12.4.' -ForegroundColor Yellow
    Write-Host 'On corrige ici uniquement cudart.lib ; une erreur de versions reste possible.' -ForegroundColor Yellow
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'INFO : cl.exe absent du PATH ; Visual Studio peut etre detecte automatiquement par nvcc.' -ForegroundColor Yellow
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
