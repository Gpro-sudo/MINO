# MINO - Lanceur compatible avec Blender installe depuis blender.org
# Les exe situes dans C:\Program Files\WindowsApps sont proteges par Windows.
$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath $PSScriptRoot

function Is-StorePath([string]$path) {
    return (-not [string]::IsNullOrEmpty($path)) -and ($path -match '(?i)\\WindowsApps\\')
}
function Is-UsableBlender([string]$path) {
    return (-not [string]::IsNullOrWhiteSpace($path)) -and
        (-not (Is-StorePath $path)) -and (Test-Path -LiteralPath $path -PathType Leaf)
}
function Find-Blender {
    # If desired, specify a custom exe using $env:MINO_BLENDER_EXE.
    if (Is-UsableBlender $env:MINO_BLENDER_EXE) { return $env:MINO_BLENDER_EXE }

    # MSI version from blender.org (prioritize this over the Microsoft Store).
    $roots = @()
    if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Blender Foundation') }
    if (${env:ProgramFiles(x86)}) { $roots += (Join-Path ${env:ProgramFiles(x86)} 'Blender Foundation') }
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        foreach ($dir in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                            Sort-Object Name -Descending)) {
            $exe = Join-Path $dir.FullName 'blender.exe'
            if (Is-UsableBlender $exe) { return $exe }
        }
    }

    # Optional portable zip placed in MINO\BlenderPortable or MINO\blender\BlenderPortable.
    foreach ($folder in @((Join-Path $PSScriptRoot 'BlenderPortable'),
                          (Join-Path (Split-Path -Parent $PSScriptRoot) 'BlenderPortable'))) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $exe = Join-Path $folder 'blender.exe'
        if (Is-UsableBlender $exe) { return $exe }
        foreach ($candidate in (Get-ChildItem -LiteralPath $folder -Recurse -Filter 'blender.exe' -File -ErrorAction SilentlyContinue)) {
            if (Is-UsableBlender $candidate.FullName) { return $candidate.FullName }
        }
    }

    # Windows PATH, but ignore executable aliases inside protected WindowsApps.
    $cmd = Get-Command 'blender.exe' -ErrorAction SilentlyContinue
    if ($cmd -and (Is-UsableBlender $cmd.Source)) { return $cmd.Source }
    return $null
}

Write-Host '[MINO] Recherche de Blender accessible...' -ForegroundColor Cyan
$exe = Find-Blender
if (-not $exe) {
    Write-Host '[MINO] Blender Microsoft Store detecte, mais il ne peut pas etre lance directement par ce script.' -ForegroundColor Yellow
    Write-Host 'Installe la version Windows Installer depuis https://www.blender.org/download/' -ForegroundColor Yellow
    Write-Host 'Choisis Windows Installer (pas Microsoft Store). Tu peux conserver les deux versions.'
    Write-Host 'Une fois l installation terminee, relance creer_mino.bat.'
    Write-Host 'Alternative : telecharge Windows Portable .zip et decompresse-le dans MINO\BlenderPortable.'
    exit 1
}

$build = Join-Path $PSScriptRoot 'build_mino.py'
if (-not (Test-Path -LiteralPath $build -PathType Leaf)) {
    Write-Host '[MINO] Fichier manquant : build_mino.py. Fais git pull origin main.' -ForegroundColor Red
    exit 2
}

Write-Host ('[MINO] Blender accessible : ' + $exe) -ForegroundColor Green
Write-Host '[MINO] Generation du modele .blend et du .glb...' -ForegroundColor Cyan
$exitCode = 1
try {
    & $exe --background --factory-startup --python $build
    if ($null -ne $LASTEXITCODE) { $exitCode = $LASTEXITCODE }
} catch {
    Write-Host ('[MINO] Impossible de lancer Blender : ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Vérifie qu il s agit de la version classique et non de WindowsApps.'
    exit 3
}
if ($exitCode -ne 0) {
    Write-Host ('[MINO] Erreur Blender (code ' + $exitCode + '). Envoie-moi les dernieres lignes.') -ForegroundColor Red
    exit 4
}

$blend = Join-Path $PSScriptRoot 'mino_rig.blend'
$glb = Join-Path $PSScriptRoot 'mino_anim.glb'
if (-not (Test-Path -LiteralPath $blend -PathType Leaf) -or
    -not (Test-Path -LiteralPath $glb -PathType Leaf)) {
    Write-Host '[MINO] Un fichier attendu est absent (.blend ou .glb).' -ForegroundColor Red
    exit 5
}
Write-Host '[MINO] Generation terminee !' -ForegroundColor Green
Write-Host ('Projet Blender : ' + $blend)
Write-Host ('Modele exporte : ' + $glb)
exit 0
