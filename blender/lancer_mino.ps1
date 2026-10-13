# MINO - Lanceur Blender pour les installations classiques et Microsoft Store.
# Lance automatiquement la scene editable et l'export .glb du kit MINO.
$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath $PSScriptRoot

function Find-Blender {
    # Installation reconnue par le PATH Windows.
    $cmd = Get-Command 'blender.exe' -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) {
        return $cmd.Source
    }

    # Installation classique par l'installateur blender.org.
    foreach ($root in @((Join-Path $env:ProgramFiles 'Blender Foundation'),
                         (Join-Path ${env:ProgramFiles(x86)} 'Blender Foundation'))) {
        if (-not $root -or -not (Test-Path -LiteralPath $root)) { continue }
        $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending
        foreach ($dir in $dirs) {
            $exe = Join-Path $dir.FullName 'blender.exe'
            if (Test-Path -LiteralPath $exe -PathType Leaf) { return $exe }
        }
    }

    # Installation via le Microsoft Store, dont les fichiers se trouvent dans WindowsApps.
    # Get-AppxPackage renvoie le vrai chemin, sans devoir acceder manuellement a WindowsApps.
    $packages = @(Get-AppxPackage -Name '*Blender*' -ErrorAction SilentlyContinue)
    foreach ($package in ($packages | Sort-Object Version -Descending)) {
        foreach ($suffix in @('Blender\blender.exe', 'blender.exe')) {
            $exe = Join-Path $package.InstallLocation $suffix
            if (Test-Path -LiteralPath $exe -PathType Leaf) { return $exe }
        }
    }

    return $null
}

Write-Host '[MINO] Recherche de Blender...' -ForegroundColor Cyan
$exe = Find-Blender

if (-not $exe) {
    Write-Host 'Blender est installe mais son chemin n a pas ete detecte automatiquement.' -ForegroundColor Yellow
    Write-Host 'Selectionne blender.exe dans la fenetre qui va s ouvrir.'
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = 'MINO - Selectionner blender.exe'
        $dialog.Filter = 'Blender (blender.exe)|blender.exe|Executables (*.exe)|*.exe'
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exe = $dialog.FileName
        }
    } catch {
        Write-Host ('Selection automatique impossible : ' + $_.Exception.Message) -ForegroundColor Yellow
    }
}

if (-not $exe -or -not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    Write-Host 'Aucun blender.exe valide selectionne. Rien n a ete modifie.' -ForegroundColor Red
    exit 1
}

$build = Join-Path $PSScriptRoot 'build_mino.py'
if (-not (Test-Path -LiteralPath $build -PathType Leaf)) {
    Write-Host 'Fichier manquant : build_mino.py. Lance le fichier depuis le kit MINO complet.' -ForegroundColor Red
    exit 2
}

Write-Host ('[MINO] Blender trouve : ' + $exe) -ForegroundColor Green
Write-Host '[MINO] Creation du projet et export 3D...' -ForegroundColor Cyan
& $exe --background --factory-startup --python $build
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host ('[MINO] Blender a retourne une erreur (code ' + $exitCode + ').') -ForegroundColor Red
    Write-Host 'Copie le dernier message affiche ici pour que je corrige le script.'
    exit 3
}

$blend = Join-Path $PSScriptRoot 'mino_rig.blend'
$glb = Join-Path $PSScriptRoot 'mino_anim.glb'
if (-not (Test-Path -LiteralPath $blend) -or -not (Test-Path -LiteralPath $glb)) {
    Write-Host 'Blender a termine mais un des fichiers attendus est absent.' -ForegroundColor Red
    exit 4
}

Write-Host ''
Write-Host '[MINO] Termine !' -ForegroundColor Green
Write-Host ('Projet Blender : ' + $blend)
Write-Host ('Modele anime   : ' + $glb)
exit 0
