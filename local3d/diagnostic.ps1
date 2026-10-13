# MINO / Diagnostic prealable a une IA 3D locale sous Windows.
# Lecture seule : n'installe rien, ne modifie rien, ne transmet aucune donnee.
$ErrorActionPreference = 'Continue'
Write-Host '========== MINO - DIAGNOSTIC 3D LOCAL ==========' -ForegroundColor Cyan
Write-Host ''

Write-Host '[1] Carte graphique et memoire video disponibles' -ForegroundColor Yellow
$nv=Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
if ($nv) {
    & $nv.Source --query-gpu=name,memory.total,memory.used,memory.free --format=csv,noheader
} else {
    Write-Host 'nvidia-smi absent'
}

Write-Host ''
Write-Host '[2] Python installe (versions connues par py)' -ForegroundColor Yellow
$py=Get-Command 'py.exe' -ErrorAction SilentlyContinue
if ($py) {
    & $py.Source -0p
} else {
    Write-Host "Le lanceur Python 'py' est introuvable."
}

Write-Host ''
Write-Host '[3] Python 3.11 x64 disponible ?' -ForegroundColor Yellow
if ($py) {
    & $py.Source -3.11 -c "import sys,platform;print(sys.version.split()[0],platform.architecture()[0])"
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Python 3.11 non detecte - nous creerons un environnement isole.'
    }
}

Write-Host ''
Write-Host '[4] Visual Studio avec outils C++' -ForegroundColor Yellow
$pf86=[Environment]::GetFolderPath('ProgramFilesX86')
$vswhere=Join-Path $pf86 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
    $vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) { Write-Host ('Outils Visual Studio C++ : ' + $vs) }
    else { Write-Host 'Outils C++ non detectes (Visual Studio Build Tools peuvent etre necessaires).' }
} else {
    Write-Host 'Visual Studio Build Tools non detecte via vswhere.'
}
Write-Host ''
Write-Host '[5] Compilateur CUDA local nvcc' -ForegroundColor Yellow
$nvcc=Get-Command 'nvcc.exe' -ErrorAction SilentlyContinue
if ($nvcc) {
    & $nvcc.Source --version | Select-Object -Last 4
} else {
    Write-Host 'nvcc absent du PATH. Le CUDA du pilote NVIDIA ne remplace pas le toolkit.'
}

Write-Host ''
Write-Host '[6] Espace libre sur disque D:' -ForegroundColor Yellow
$d=Get-PSDrive -Name D -PSProvider FileSystem -ErrorAction SilentlyContinue
if ($d) {
    Write-Host ('Libre : {0:N1} Go' -f ($d.Free / 1GB))
} else {
    Write-Host 'Disque D: non detecte.'
}
Write-Host ''
Write-Host '[7] Memoire vive' -ForegroundColor Yellow
try {
    $c=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    Write-Host ('RAM : {0:N1} Go' -f ($c.TotalPhysicalMemory/1GB))
} catch {
    Write-Host 'RAM non determinee.'
}
Write-Host ''
Write-Host '========= FIN (aucune modification effectuee) =========' -ForegroundColor Green
