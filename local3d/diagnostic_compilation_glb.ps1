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
Write-Host '========== FIN DIAGNOSTIC, AUCUNE MODIFICATION ==========' -ForegroundColor Green
Write-Host 'Envoie ce resultat ET les dernieres lignes de l erreur SaveGLBFile (fin du rapport).'
