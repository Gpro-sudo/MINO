# MINO : dependances TRELLIS de base sous Python 3.10, CUDA 12.4.
# Toute installation est limitee a local3d/trellis_lab/.venv.
# Aucun paquet dans ComfyUI Pinokio, aucun modele 3D telecharge.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$lab = Join-Path $root 'trellis_lab'
$python = Join-Path $lab '.venv\Scripts\python.exe'
$node = Join-Path $lab 'ComfyUI\custom_nodes\ComfTrellis'
$patch = Join-Path $root 'neutraliser_autoinstall_trellis.py'
$test = Join-Path $root 'test_trellis_libraries.py'
$constraints = Join-Path $lab 'mino_constraints.txt'

Write-Host ''
Write-Host '========== MINO / DEPENDANCES TRELLIS ISOLEES ==========' -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host 'ERREUR : environnement TRELLIS absent.' -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $node '__init__.py') -PathType Leaf)) {
    Write-Host 'ERREUR : sources ComfTrellis absentes.' -ForegroundColor Red
    exit 2
}

Write-Host '[1/5] Desactivation de l auto-installateur du noeud (copie locale)' -ForegroundColor Yellow
& $python $patch
if ($LASTEXITCODE -ne 0) { exit 3 }

Write-Host ''
Write-Host '[2/5] Protection des versions deja validees (PyTorch et NumPy)' -ForegroundColor Yellow
@(
    'torch==2.5.1+cu124'
    'torchvision==0.20.1+cu124'
    'xformers==0.0.28.post3'
    'numpy==1.26.4'
) | Set-Content -LiteralPath $constraints -Encoding UTF8
& $python (Join-Path $root 'test_trellis_torch.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : PyTorch GPU n est plus valide. Arret avant installation.' -ForegroundColor Red
    exit 4
}

Write-Host ''
Write-Host '[3/5] Paquets Python de reconstruction et traitement images' -ForegroundColor Yellow
$packages = @(
    'imageio'
    'imageio-ffmpeg'
    'easydict'
    'opencv-python-headless==4.11.0.86'
    'rembg==2.0.57'
    'onnxruntime'
    'trimesh'
    'xatlas'
    'pyvista'
    'plyfile'
    'pymeshfix'
    'igraph'
    'huggingface-hub'
    'ninja'
)
& $python -m pip install --disable-pip-version-check --prefer-binary -c $constraints @packages
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : paquets de base. Envoie les dernieres lignes.' -ForegroundColor Red
    exit 5
}

Write-Host ''
Write-Host '[4/5] Kaolin NVIDIA compatible Torch 2.5.1 CUDA 12.4' -ForegroundColor Yellow
& $python -m pip install --disable-pip-version-check --prefer-binary -c $constraints 'kaolin==0.17.0' -f 'https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.5.1_cu124.html'
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : Kaolin. Ne change pas les versions PyTorch.' -ForegroundColor Red
    exit 6
}

Write-Host ''
Write-Host '[5/5] SpConv CUDA 12.4, puis verification des imports' -ForegroundColor Yellow
& $python -m pip install --disable-pip-version-check --prefer-binary -c $constraints 'spconv-cu124'
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : SpConv CUDA 12.4. Arret.' -ForegroundColor Red
    exit 7
}
& $python $test
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : au moins un import echoue. Envoie les dernieres lignes.' -ForegroundColor Red
    exit 8
}

Write-Host ''
Write-Host '========== TRELLIS : DEPENDANCES DE BASE PRETES ==========' -ForegroundColor Green
Write-Host 'ComfyUI Pinokio n a pas ete modifie.'
Write-Host 'Ne demarre pas encore le laboratoire TRELLIS.'
Write-Host 'Il reste les extensions de rasterisation natives et ComfyUI.'
exit 0
