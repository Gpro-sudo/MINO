# MINO - Prepare un laboratoire TRELLIS isole de Pinokio.
# Le script ne lance pas ComfyUI et n'installe PAS de paquet Python.
# Il clone uniquement les sources de ComfyUI et du noeud ComfTrellis dans MINO.
# Un Python virtuel 3.10 est prepare a part, sans toucher a Pinokio.
$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'trellis_lab'
$comfy = Join-Path $base 'ComfyUI'
$node = Join-Path $comfy 'custom_nodes\ComfTrellis'
$venv = Join-Path $base '.venv'
$venvPy = Join-Path $venv 'Scripts\python.exe'
$pinokioPython = 'D:\pinokio\bin\miniforge\python.exe'
$pinokioComfyPy = 'D:\pinokio\api\comfy.git\app\env\Scripts\python.exe'

function Invoke-Checked {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Echec de $File (code $LASTEXITCODE). Rien n'a ete supprime."
    }
}

Write-Host '========== MINO : PREPARATION TRELLIS ISOLEE ==========' -ForegroundColor Cyan
Write-Host 'Pinokio/ComfyUI actuel non modifie.' -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $pinokioPython -PathType Leaf)) {
    throw "Python 3.10 de Pinokio introuvable : $pinokioPython"
}
if (-not (Test-Path -LiteralPath $pinokioComfyPy -PathType Leaf)) {
    throw "Python ComfyUI de Pinokio introuvable : $pinokioComfyPy"
}
Write-Host '[1/5] Versions Python deja installees'
Invoke-Checked $pinokioPython @('--version')
Invoke-Checked $pinokioComfyPy @('--version')

$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) { throw 'Git est absent du PATH.' }

Write-Host ''
Write-Host '[2/5] Dossier dedie MINO / TRELLIS'
New-Item -Path $base -ItemType Directory -Force | Out-Null
Write-Host $base

Write-Host ''
Write-Host '[3/5] Copie independante du code officiel ComfyUI'
if (-not (Test-Path -LiteralPath (Join-Path $comfy 'main.py') -PathType Leaf)) {
    if (Test-Path -LiteralPath $comfy) {
        throw "Le dossier ComfyUI existe mais ne contient pas main.py : $comfy. Aucun fichier supprime."
    }
    Invoke-Checked $git.Source @('clone', '--depth', '1', 'https://github.com/Comfy-Org/ComfyUI.git', $comfy)
} else {
    Write-Host 'Deja present : copie du code conservee.'
}

Write-Host ''
Write-Host '[4/5] Sources ComfTrellis (sans les importer ni les executer)'
if (-not (Test-Path -LiteralPath (Join-Path $node '__init__.py') -PathType Leaf)) {
    if (Test-Path -LiteralPath $node) {
        throw "Le dossier ComfTrellis est incomplet : $node. Aucun fichier supprime."
    }
    Invoke-Checked $git.Source @('clone', '--depth', '1', 'https://github.com/Scaryplasmon/ComfTrellis.git', $node)
} else {
    Write-Host 'Deja present : aucun reclonage.'
}
Write-Host 'IMPORTANT : ne pas demarrer cette copie de ComfyUI avant la preparation des dependances.'
Write-Host 'Le noeud contient un installateur automatique qui pourrait changer PyTorch, mais il restera dans ce laboratoire.'

Write-Host ''
Write-Host '[5/5] Environnement Python 3.10 distinct'
if (-not (Test-Path -LiteralPath $venvPy -PathType Leaf)) {
    $uvCommand = Get-Command uv.exe -ErrorAction SilentlyContinue
    $uvPath = if ($uvCommand) { $uvCommand.Source } else { Join-Path $env:USERPROFILE '.local\bin\uv.exe' }
    if (Test-Path -LiteralPath $uvPath -PathType Leaf) {
        Invoke-Checked $uvPath @('venv', '--python', $pinokioPython, '--seed', '--link-mode', 'copy', $venv)
    } else {
        Invoke-Checked $pinokioPython @('-m', 'venv', $venv)
    }
} else {
    Write-Host 'Environnement virtuel deja present.'
}
if (-not (Test-Path -LiteralPath $venvPy -PathType Leaf)) {
    throw "Python isole non cree sous : $venvPy"
}
Invoke-Checked $venvPy @('--version')
Write-Host ''
Write-Host '========== PREPARATION TERMINEE ==========' -ForegroundColor Green
Write-Host ('Laboratoire : ' + $base)
Write-Host ('Python isole : ' + $venvPy)
Write-Host 'Aucun modele TRELLIS, PyTorch ou extension CUDA installe.'
Write-Host 'ComfyUI de Pinokio reste inchange. Ne lance pas encore la copie TRELLIS.'
Write-Host 'Transmets-moi le resultat pour installer PyTorch 2.5.1 CUDA 12.4 uniquement dans ce laboratoire.'
