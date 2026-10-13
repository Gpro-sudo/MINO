# MINO / TRELLIS : lecture seule des outils utilises lors d'un echec d'export GLB.
# Aucune installation, aucune compilation, aucune modification de configuration.
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$python = Join-Path $root 'trellis_lab\.venv\Scripts\python.exe'
Write-Host '========== MINO / DIAGNOSTIC COMPILATION GLB ==========' -ForegroundColor Cyan
Write-Host 'Ce script ne change rien a TRELLIS, ComfyUI ou Pinokio.'
Write-Host ''
Write-Host '[1] Executables dans le PATH' -ForegroundColor Yellow
foreach ($name in @('ninja.exe', 'nvcc.exe', 'cl.exe')) {
    $found = @(Get-Command -Name $name -All -ErrorAction SilentlyContinue |
        Where-Object { $_.Source } |
        Select-Object -ExpandProperty Source -Unique)
    if ($found.Count -eq 0) {
        Write-Host ('ABSENT : ' + $name)
    } else {
        foreach ($path in $found) { Write-Host ($name + ' : ' + $path) }
    }
}
Write-Host ''
Write-Host '[2] Versions Ninja et nvcc du PATH' -ForegroundColor Yellow
if (Get-Command 'ninja.exe' -ErrorAction SilentlyContinue) {
    & ninja.exe --version
}
if (Get-Command 'nvcc.exe' -ErrorAction SilentlyContinue) {
    & nvcc.exe --version
}
Write-Host ''
Write-Host '[3] Variables CUDA' -ForegroundColor Yellow
foreach ($name in @('CUDA_HOME', 'CUDA_PATH', 'CUDA_PATH_V12_4', 'CUDA_PATH_V13_0', 'CUDA_PATH_V13_4', 'CXX', 'CC', 'TORCH_CUDA_ARCH_LIST')) {
    $value = [Environment]::GetEnvironmentVariable($name, 'Process')
    if ($value) { Write-Host ($name + ' = ' + $value) }
}
Write-Host ''
Write-Host '[4] PyTorch et compilateur CUDA retenu dans le laboratoire' -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host ('ERREUR : Python introuvable : ' + $python)
    exit 1
}
& $python (Join-Path $root 'diagnostic_compilation_glb.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERREUR : diagnostic Python impossible.'
    exit 2
}
Write-Host ''
Write-Host '[5] Compilateur Microsoft connu (sans rien installer)' -ForegroundColor Yellow
$programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
$vswhere = Join-Path $programFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
    & $vswhere -latest -products '*' -property installationPath
} else {
    Write-Host 'vswhere.exe absent du chemin Visual Studio standard.'
}
Write-Host ''
Write-Host '[6] Recherche de cudart.lib (bibliotheque de liaison CUDA)' -ForegroundColor Yellow
$roots = @(
    $env:CUDA_HOME
    $env:CUDA_PATH
    'D:\pinokio\bin\miniforge\Library'
    'D:\pinokio\bin\miniforge'
    (Join-Path $root 'trellis_lab\.venv\Lib\site-packages\torch')
)
foreach ($toolkitBase in @(
    'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA'
    'D:\Program Files\NVIDIA GPU Computing Toolkit\CUDA'
)) {
    if (Test-Path -LiteralPath $toolkitBase -PathType Container) {
        $roots += @(Get-ChildItem -LiteralPath $toolkitBase -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName)
    }
}
$condaPkgs = 'D:\pinokio\bin\miniforge\pkgs'
if (Test-Path -LiteralPath $condaPkgs -PathType Container) {
    $roots += @(Get-ChildItem -LiteralPath $condaPkgs -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '(?i)cudart|cuda-nvcc|cuda-toolkit' } |
        Select-Object -ExpandProperty FullName)
}
$foundLibs = @()
foreach ($prefix in ($roots | Where-Object { $_ } | Select-Object -Unique)) {
    foreach ($subpath in @('lib\x64\cudart.lib', 'lib\cudart.lib', 'Library\lib\x64\cudart.lib', 'Library\lib\cudart.lib', 'cudart.lib')) {
        $candidate = Join-Path $prefix $subpath
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $fullPath = (Get-Item -LiteralPath $candidate).FullName
            if ($foundLibs -notcontains $fullPath) {
                $foundLibs += $fullPath
                $size = (Get-Item -LiteralPath $candidate).Length
                Write-Host ('TROUVE : ' + $fullPath + ' (' + $size + ' octets)') -ForegroundColor Green
            }
        }
    }
}
if ($foundLibs.Count -eq 0) {
    Write-Host 'INTROUVABLE aux emplacements habituels sur C: et D:.' -ForegroundColor Yellow
    Write-Host 'Le paquet de developpement CUDA (contenant cudart.lib) pourrait etre absent.'
    Write-Host 'Ne telecharge aucun fichier .lib isole depuis un site non officiel.'
}
Write-Host ''
Write-Host 'IMPORTANT : une bibliotheque 12.4 est preferable, car PyTorch utilise CUDA 12.4.'
Write-Host 'Ne change pas CUDA_HOME, CUDA_PATH ou le PATH systeme avant verification.'
Write-Host ''
Write-Host '========== FIN DIAGNOSTIC, AUCUNE MODIFICATION ==========' -ForegroundColor Green
Write-Host 'Envoie ce resultat ET les dernieres lignes de l erreur SaveGLBFile (fin du rapport).'
