# MINO - Installer ComfyUI 0.3.31 dans le laboratoire TRELLIS sans modifier Pinokio.
# Python 3.10, PyTorch 2.5.1 CUDA 12.4 ; le modele TRELLIS n'est pas telecharge ici.
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$lab = Join-Path $root 'trellis_lab'
$comfy = Join-Path $lab 'ComfyUI'
$node = Join-Path $comfy 'custom_nodes\ComfTrellis\__init__.py'
$python = Join-Path $lab '.venv\Scripts\python.exe'
$constraints = Join-Path $lab 'mino_constraints.txt'
$comfyVersion = 'v0.3.31'

function Invoke-Checked {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Commande echouee (code $LASTEXITCODE) : $File $($Arguments -join ' ')"
    }
}

Write-Host ''
Write-Host '========== MINO / COMFYUI TRELLIS ISOLE ==========' -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    throw "Environnement TRELLIS introuvable : $python"
}
if (-not (Test-Path -LiteralPath (Join-Path $comfy 'main.py') -PathType Leaf)) {
    throw "Copie du ComfyUI isole introuvable : $comfy"
}
if (-not (Test-Path -LiteralPath $node -PathType Leaf)) {
    throw "Noeud ComfTrellis introuvable : $node"
}
$nodeText = Get-Content -LiteralPath $node -Raw
if (-not $nodeText.Contains('MINO LAB ONLY: installation automatique desactivee.')) {
    throw "Auto-installateur ComfTrellis non neutralise. Relance installer_trellis_bibliotheques.ps1 AVANT cette etape."
}

Write-Host '[1/5] Verification initiale du GPU TRELLIS' -ForegroundColor Yellow
Invoke-Checked $python @((Join-Path $root 'test_trellis_torch.py'))
Invoke-Checked $python @((Join-Path $root 'test_trellis_extensions.py'))

Write-Host ''
Write-Host '[2/5] Selection d une version ComfyUI correspondant a TRELLIS 2025' -ForegroundColor Yellow
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) { throw 'Git introuvable dans le PATH.' }
$trackedChanges = @(& $git.Source -C $comfy status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) { throw "Impossible de lire l'etat Git du ComfyUI isole." }
if ($trackedChanges.Count -gt 0 -and (($trackedChanges -join '')).Trim().Length -gt 0) {
    throw 'Le ComfyUI isole comporte des modifications suivies : refus de changer sa version.'
}
$currentTag = (& $git.Source -C $comfy describe --tags --exact-match HEAD 2>$null)
if ($LASTEXITCODE -ne 0) { $currentTag = '' }
if ("$currentTag".Trim() -ne $comfyVersion) {
    Write-Host ('Recuperation du tag ' + $comfyVersion + ' (seulement dans trellis_lab)')
    Invoke-Checked $git.Source @('-C', $comfy, 'fetch', '--depth', '1', 'origin', 'tag', $comfyVersion)
    Invoke-Checked $git.Source @('-C', $comfy, 'checkout', '--detach', $comfyVersion)
}
Write-Host ('ComfyUI : ' + $comfyVersion)
if (-not (Test-Path -LiteralPath $node -PathType Leaf)) {
    throw 'Le noeud TRELLIS est introuvable apres changement de version (ne supprime aucun fichier).'
}

Write-Host ''
Write-Host '[3/5] Contraintes : preservation de PyTorch/cu124, NumPy et Transformers' -ForegroundColor Yellow
@(
    'torch==2.5.1+cu124'
    'torchvision==0.20.1+cu124'
    'torchaudio==2.5.1+cu124'
    'xformers==0.0.28.post3'
    'numpy==1.26.4'
    'transformers==4.48.3'
    'huggingface-hub==0.34.4'
) | Set-Content -LiteralPath $constraints -Encoding ASCII
Write-Host 'Installation torchaudio compatible CUDA 12.4 (si absent)'
Invoke-Checked $python @(
    '-m', 'pip', 'install', '--disable-pip-version-check', '--prefer-binary',
    '-c', $constraints, 'torchaudio==2.5.1',
    '--index-url', 'https://download.pytorch.org/whl/cu124'
)

Write-Host ''
Write-Host '[4/5] Dependances de ComfyUI v0.3.31, uniquement dans le venv TRELLIS' -ForegroundColor Yellow
$requirements = Join-Path $comfy 'requirements.txt'
if (-not (Test-Path -LiteralPath $requirements -PathType Leaf)) {
    throw 'requirements.txt de ComfyUI introuvable.'
}
Invoke-Checked $python @(
    '-m', 'pip', 'install', '--disable-pip-version-check',
    '--prefer-binary', '-c', $constraints,
    '-r', $requirements
)

Write-Host ''
Write-Host '[5/5] Verification des bibliotheques et du GPU sans serveur' -ForegroundColor Yellow
Invoke-Checked $python @((Join-Path $root 'test_comfyui_trellis.py'))
Write-Host ''
Write-Host '========== MINO / COMFYUI TRELLIS PRET POUR DEMARRAGE ==========' -ForegroundColor Green
Write-Host ('Code isole : ' + $comfy)
Write-Host ('Python isole : ' + $python)
Write-Host 'Aucun modele TRELLIS telecharge. Pinokio ComfyUI non modifie.'
Write-Host 'Envoie-moi ce resultat pour demarrer le serveur isole sur http://127.0.0.1:8189.'
