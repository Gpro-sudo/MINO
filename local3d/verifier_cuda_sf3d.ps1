# MINO / Verification de la compilation Stable Fast 3D avec CUDA de Pinokio.
# Lecture seule : aucun fichier installe ou modifie. PATH/CUDA_HOME locaux au processus.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

Write-Host ''
Write-Host '========== MINO - CONTROLE TOOLKIT CUDA SF3D ==========' -ForegroundColor Cyan
$nvccPath = $null
$candidates = @(
    'D:\pinokio\bin\miniforge\Library\bin\nvcc.exe',
    (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'NVIDIA GPU Computing Toolkit\CUDA\v12.1\bin\nvcc.exe')
)
foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $nvccPath = $candidate
        break
    }
}
if (-not $nvccPath) {
    $found = Get-Command 'nvcc.exe' -ErrorAction SilentlyContinue
    if ($found) { $nvccPath = $found.Source }
}
if (-not $nvccPath) {
    Write-Host '[ECHEC] Aucun nvcc.exe detecte. Rien n a ete modifie.' -ForegroundColor Red
    exit 1
}

$cudaBin = Split-Path -Path $nvccPath -Parent
$cudaRoot = Split-Path -Path $cudaBin -Parent
$env:CUDA_HOME = $cudaRoot
$env:CUDA_PATH = $cudaRoot
$env:Path = $cudaBin + ';' + $env:Path
Write-Host ('Compilateur : ' + $nvccPath)
Write-Host ('CUDA_HOME pour la verification : ' + $cudaRoot)
& $nvccPath --version | Select-Object -Last 4
if ($LASTEXITCODE -ne 0) {
    Write-Host '[ECHEC] nvcc existe mais son execution a echoue.' -ForegroundColor Red
    exit 2
}

Write-Host ''
Write-Host '[1] Fichiers necessaires a la compilation' -ForegroundColor Yellow
$headers = @(
    (Join-Path $cudaRoot 'include\cuda_runtime.h'),
    (Join-Path $cudaRoot 'include\cuda.h')
)
$libs = @(
    (Join-Path $cudaRoot 'lib\x64\cudart.lib'),
    (Join-Path $cudaRoot 'lib\x64\cudart_static.lib')
)
$missing = @()
foreach ($path in ($headers + $libs)) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Write-Host ('OK : ' + $path) -ForegroundColor Green
    } else {
        Write-Host ('ABSENT : ' + $path) -ForegroundColor Yellow
        $missing += $path
    }
}

Write-Host ''
Write-Host '[2] PyTorch et detection CUDA_HOME' -ForegroundColor Yellow
$python = Join-Path $PSScriptRoot '.venv-sf3d\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host 'ABSENT : environnement Python MINO' -ForegroundColor Red
    exit 3
}
$check = 'import torch,numpy;from torch.utils.cpp_extension import CUDA_HOME;print("PyTorch:",torch.__version__,"- CUDA:",torch.version.cuda);print("GPU operationnel:",torch.cuda.is_available());print("CUDA_HOME vu par PyTorch:",CUDA_HOME);print("NumPy:",numpy.__version__)'
& $python -c $check
if ($LASTEXITCODE -ne 0) { exit 4 }

Write-Host ''
Write-Host '[3] Outils C++ Visual Studio' -ForegroundColor Yellow
$vswhere = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
    $compiler = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find 'VC/Tools/MSVC/*/bin/Hostx64/x64/cl.exe'
    if ($compiler) {
        Write-Host ('Compilateur C++ : ' + ($compiler | Select-Object -First 1)) -ForegroundColor Green
    } else {
        Write-Host 'ATTENTION : cl.exe non detecte.' -ForegroundColor Yellow
    }
} else {
    Write-Host 'ATTENTION : vswhere.exe non detecte.' -ForegroundColor Yellow
}

Write-Host ''
if ($missing.Count -gt 0) {
    Write-Host ('RESULTAT : nvcc fonctionne, mais ' + $missing.Count + ' composant(s) CUDA non detecte(s).') -ForegroundColor Yellow
    Write-Host 'Une installation CUDA 12.1 separee pourra etre necessaire pour les extensions natives.'
} else {
    Write-Host 'RESULTAT : nvcc, les en-tetes et les bibliotheques CUDA sont detectes.' -ForegroundColor Green
    Write-Host 'Nous pourrons essayer la compilation Windows, avec adaptation des options MSVC.'
}
Write-Host 'Le CUDA Toolkit de Pinokio et celui de PyTorch ont des versions mineures differentes : compilation NON ENCORE VERIFIEE.'
Write-Host 'Ce test ne modifie pas Pinokio, CUDA, Windows ou le jeu MINO.'
