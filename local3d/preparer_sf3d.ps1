# MINO - Preparer un environnement Python ISOLE pour Stable Fast 3D.
# N'installe PAS CUDA, PyTorch ou les poids du modele.
# Cree seulement un environnement virtuel local, reutilisant Python 3.11 existant.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Find-Python311 {
    # Priorite a l'installation Python 3.11 x64 geree par uv deja presente sur le PC.
    $uvPython = Join-Path $env:APPDATA 'uv\python'
    if (Test-Path -LiteralPath $uvPython -PathType Container) {
        $dirs = Get-ChildItem -LiteralPath $uvPython -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^cpython-3\.11\.\d+-windows-x86_64-none$' } |
            Sort-Object Name -Descending
        foreach ($dir in $dirs) {
            $candidate = Join-Path $dir.FullName 'python.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
        }
    }
    # Recherche alternative de l'interpreteur Python 3.11 deja declare dans PATH.
    $python = Get-Command 'python.exe' -ErrorAction SilentlyContinue
    if ($python) {
        $valid = & $python.Source -c "import sys,struct;print(int(sys.version_info[:2]==(3,11) and struct.calcsize('P')==8))" 2>$null
        if ($LASTEXITCODE -eq 0 -and $valid -eq '1') { return $python.Source }
    }
    return $null
}

Write-Host ''
Write-Host '========== MINO - PREPARATION PYTHON 3D LOCAL ==========' -ForegroundColor Cyan
$python = Find-Python311
if (-not $python) {
    Write-Host 'Python 3.11 x64 introuvable. Rien n a ete modifie.' -ForegroundColor Red
    Write-Host 'Teste : uv python list --only-installed'
    exit 1
}
Write-Host ('Python retenu : ' + $python) -ForegroundColor Green
& $python -c "import sys,struct; assert sys.version_info[:2] == (3,11) and struct.calcsize('P') == 8; print('Python',sys.version.split()[0],'- 64 bits OK')"

$venv = Join-Path $PSScriptRoot '.venv-sf3d'
$venvPython = Join-Path $venv 'Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
    Write-Host 'Creation de l environnement Python isole...' -ForegroundColor Cyan
    $uvCommand = Get-Command 'uv.exe' -ErrorAction SilentlyContinue
    $uvPath = if ($uvCommand) { $uvCommand.Source } else { $null }
    if (-not $uvPath) {
        $possibleUv = Join-Path $env:USERPROFILE '.local\bin\uv.exe'
        if (Test-Path -LiteralPath $possibleUv -PathType Leaf) {
            $uvPath = $possibleUv
        }
    }
    if ($uvPath) {
        & $uvPath venv --python $python --seed $venv
    } else {
        & $python -m venv $venv
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Creation du venv impossible. Envoie-moi la sortie de cette commande.' -ForegroundColor Red
        exit 2
    }
}
if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
    Write-Host 'Echec : Scripts\python.exe non cree dans le dossier virtuel.' -ForegroundColor Red
    exit 3
}
Write-Host ('Environnement cree : ' + $venv) -ForegroundColor Green
& $venvPython -c "import sys,platform;print('Interpreteur local:',sys.executable);print('Architecture:',platform.architecture()[0])"
Write-Host ''
Write-Host 'Verification des outils CUDA...' -ForegroundColor Cyan
$nvcc = Get-Command 'nvcc.exe' -ErrorAction SilentlyContinue
if ($nvcc) {
    & $nvcc.Source --version | Select-Object -Last 4
} else {
    Write-Host 'nvcc absent du PATH : il faudra verifier/installer le CUDA Toolkit compatible, avant la compilation de SF3D.' -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'PREPARATION TERMINEE : aucun modele IA ni PyTorch installe.' -ForegroundColor Green
Write-Host 'Envoie-moi cette sortie. Nous choisirons ensuite une version CUDA/PyTorch compatible.'
