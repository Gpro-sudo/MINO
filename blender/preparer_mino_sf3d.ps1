# MINO — Etape 1 : importer le vrai modele SF3D en conservant ses textures.
# Le script ne modifie ni le GLB original ni le jeu MINO 0.5.
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$root = Split-Path -Parent $here
$model = Join-Path $root 'local3d\output\mino\0\mesh.glb'
$script = Join-Path $here 'preparer_mino_sf3d.py'

if (-not (Test-Path -LiteralPath $model -PathType Leaf)) {
    Write-Host '[MINO] Fichier manquant :' $model -ForegroundColor Red
    Write-Host '[MINO] Relance la generation locale avec generer_sf3d.cmd.'
    exit 1
}

if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    Write-Host '[MINO] preparer_mino_sf3d.py introuvable ; fais git pull.' -ForegroundColor Red
    exit 2
}

$blender = $null
if ($env:MINO_BLENDER_EXE -and (Test-Path -LiteralPath $env:MINO_BLENDER_EXE -PathType Leaf)) {
    $blender = $env:MINO_BLENDER_EXE
}
if (-not $blender) {
    $known = 'D:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
    if (Test-Path -LiteralPath $known -PathType Leaf) { $blender = $known }
}
if (-not $blender) {
    $roots = @()
    if ($env:ProgramFiles) {
        $roots += (Join-Path $env:ProgramFiles 'Blender Foundation')
    }
    foreach ($drive in @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        $roots += (Join-Path (Join-Path $drive.Root 'Program Files') 'Blender Foundation')
    }
    foreach ($folder in ($roots | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($dir in (Get-ChildItem -LiteralPath $folder -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $exe = Join-Path $dir.FullName 'blender.exe'
            if (Test-Path -LiteralPath $exe -PathType Leaf) {
                $blender = $exe
                break
            }
        }
        if ($blender) { break }
    }
}
if (-not $blender) {
    Write-Host '[MINO] Blender classique introuvable. Utilise MINO_BLENDER_EXE pour pointer vers blender.exe.' -ForegroundColor Red
    exit 3
}

Write-Host '[MINO] Blender :' $blender -ForegroundColor Cyan
Write-Host '[MINO] Modele :' $model
Write-Host '[MINO] Preparation du projet editable avec textures integrees...' -ForegroundColor Cyan

try {
    & $blender --background --factory-startup --python $script
} catch {
    Write-Host ('[MINO] Blender ne peut pas etre lance : ' + $_.Exception.Message) -ForegroundColor Red
    exit 4
}
if ($LASTEXITCODE -ne 0) {
    Write-Host ('[MINO] Echec Blender (code ' + $LASTEXITCODE + '). Envoie les dernieres lignes.') -ForegroundColor Red
    exit 5
}
$projects = @(Get-ChildItem -LiteralPath $here -Filter 'mino_sf3d_base*.blend' -File | Sort-Object LastWriteTime -Descending)
if ($projects.Count -eq 0) {
    Write-Host '[MINO] Aucun .blend SF3D produit.' -ForegroundColor Red
    exit 6
}

Write-Host '[MINO] Fichier a ouvrir dans Blender :' $projects[0].FullName -ForegroundColor Green
Write-Host '[MINO] Envoie une capture de face en couleurs, puis une vue de profil.'
exit 0
