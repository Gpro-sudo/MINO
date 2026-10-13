# MINO - installer les EXTENSIONS TRELLIS precompilees sous Windows.
# Installation limitee a local3d/trellis_lab/.venv ; Pinokio ComfyUI reste intact.
# Sources : 3 roues fournies avec ComfTrellis et 2 roues communautaires Comfy3D
# cibles pour CPython 3.10 / PyTorch 2.5.1 / CUDA 12.4.
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$lab = Join-Path $base 'trellis_lab'
$python = Join-Path $lab '.venv\Scripts\python.exe'
$node = Join-Path $lab 'ComfyUI\custom_nodes\ComfTrellis'
$wheelCache = Join-Path $lab 'wheels'

if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host 'ERREUR : Python de laboratoire TRELLIS introuvable.' -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $node '__init__.py') -PathType Leaf)) {
    Write-Host 'ERREUR : code ComfTrellis introuvable.' -ForegroundColor Red
    exit 2
}

Write-Host ''
Write-Host '========== MINO / EXTENSIONS TRELLIS WINDOWS ==========' -ForegroundColor Cyan
Write-Host ('Python isole : ' + $python)
Write-Host 'Pinokio et Stable Fast 3D ne sont pas modifies.' -ForegroundColor Yellow

Write-Host ''
Write-Host '[1/4] Controle PyTorch 2.5.1/cu124 et xformers' -ForegroundColor Cyan
& $python (Join-Path $base 'test_trellis_torch.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : PyTorch/xformers non valide. Stop avant les roues natives.' -ForegroundColor Red
    exit 3
}

Write-Host ''
Write-Host '[2/4] Recuperation et verification des deux roues communautaires' -ForegroundColor Cyan
& $python (Join-Path $base 'telecharger_roues_trellis.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : roues non telechargees/verifiees. Aucun paquet natif installe.' -ForegroundColor Red
    exit 4
}

Write-Host ''
Write-Host '[3/4] Installation exclusivement de roues locales, SANS dependances' -ForegroundColor Cyan
$wheels = @(
    (Join-Path $node 'wheels\diff_gaussian_rasterization\diff_gaussian_rasterization-0.0.0-cp310-cp310-win_amd64.whl')
    (Join-Path $node 'wheels\diffoctreerast\diffoctreerast-0.0.0-cp310-cp310-win_amd64.whl')
    (Join-Path $node 'wheels\utils3d\utils3d-0.0.2-py3-none-any.whl')
    (Join-Path $wheelCache 'nvdiffrast-0.3.3-py3-none-any.whl')
    (Join-Path $wheelCache 'vox2seq-0.0.0-cp310-cp310-win_amd64.whl')
)
foreach ($wheel in $wheels) {
    if (-not (Test-Path -LiteralPath $wheel -PathType Leaf)) {
        Write-Host ('ERREUR : archive absente : ' + $wheel) -ForegroundColor Red
        exit 5
    }
}
foreach ($wheel in $wheels) {
    Write-Host ('Installation : ' + (Split-Path -Leaf $wheel)) -ForegroundColor Yellow
    & $python -m pip install --disable-pip-version-check --no-index --no-deps $wheel
    if ($LASTEXITCODE -ne 0) {
        Write-Host ('ERREUR : roue impossible a installer : ' + $wheel) -ForegroundColor Red
        Write-Host 'Envoie les dernieres lignes. Ne reinstalle pas tout TRELLIS.'
        exit 6
    }
}

Write-Host ''
Write-Host '[4/4] Imports des extensions dans le venv (sans demarrer ComfyUI)' -ForegroundColor Cyan
& $python (Join-Path $base 'test_trellis_extensions.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : des extensions natives sont installees mais leur import echoue.' -ForegroundColor Red
    Write-Host 'Envoie les lignes ECHEC. Ne lance pas encore ComfyUI/TRELLIS.'
    exit 7
}

Write-Host ''
Write-Host '========== MINO : EXTENSIONS NATIVES INSTALLEES ==========' -ForegroundColor Green
Write-Host 'Prochaine etape : installer/tester ComfyUI dans le laboratoire, puis les poids TRELLIS.'
Write-Host 'Ne demarre pas encore le laboratoire manuellement.'
exit 0
