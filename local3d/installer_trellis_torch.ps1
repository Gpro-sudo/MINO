# MINO - PyTorch CUDA 12.4 uniquement dans TRELLIS LAB (Windows).
# N'execute aucun noeud TRELLIS et ne change pas le ComfyUI de Pinokio.
$ErrorActionPreference = 'Stop'
$lab = Join-Path $PSScriptRoot 'trellis_lab'
$python = Join-Path $lab '.venv\Scripts\python.exe'
$test = Join-Path $PSScriptRoot 'test_trellis_torch.py'

Write-Host ''
Write-Host '========== MINO / INSTALLATION PYTORCH TRELLIS ISOLE ==========' -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host 'Environnement TRELLIS non trouve : lance preparer_trellis_isole.ps1.' -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath $test -PathType Leaf)) {
    Write-Host 'Fichier test_trellis_torch.py introuvable : fais git pull.' -ForegroundColor Red
    exit 2
}

Write-Host ('Python cible : ' + $python) -ForegroundColor Cyan
& $python --version
if ($LASTEXITCODE -ne 0) { exit 3 }

Write-Host ''
Write-Host '[1/3] NumPy 1.26.4 (compatible avec les extensions anciennes de TRELLIS)' -ForegroundColor Yellow
& $python -m pip install --disable-pip-version-check 'numpy==1.26.4'
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ECHEC : installation de NumPy dans le laboratoire.' -ForegroundColor Red
    exit 4
}

Write-Host ''
Write-Host '[2/3] PyTorch 2.5.1 / torchvision 0.20.1 / xformers 0.0.28.post3' -ForegroundColor Yellow
Write-Host 'Versions Windows CUDA 12.4 officielles. Telechargements volumineux.' -ForegroundColor Yellow
& $python -m pip install --disable-pip-version-check --prefer-binary 'torch==2.5.1' 'torchvision==0.20.1' 'xformers==0.0.28.post3' --index-url 'https://download.pytorch.org/whl/cu124'
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ECHEC : installation PyTorch CUDA 12.4 dans le laboratoire.' -ForegroundColor Red
    Write-Host 'Ne reinstalle pas Pinokio ni Python : transmets-moi les dernieres lignes de pip.'
    exit 5
}

Write-Host ''
Write-Host '[3/3] Test calcul GPU et noyau xformers' -ForegroundColor Yellow
& $python $test
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ECHEC : PyTorch est peut-etre installe, mais le test GPU a echoue.' -ForegroundColor Red
    Write-Host 'Transmets-moi le message de test sans relancer l installation.'
    exit 6
}

Write-Host ''
Write-Host '========== SUCCES PYTORCH TRELLIS LAB ==========' -ForegroundColor Green
Write-Host 'PyTorch est valide dans un environnement distinct de Pinokio/ComfyUI.'
Write-Host 'Aucun modele TRELLIS, noeud ComfyUI ou autres extensions installe ici.'
Write-Host 'Envoie-moi ce resultat pour l etape suivante.'
exit 0
