# MINO - Verifie ComfTrellis via le serveur local 8189 et prepare la reference.
# Aucun modele, paquet Python ou script tiers execute.
# Utiliser pendant que lancer_comfyui_trellis.ps1 fonctionne dans une autre fenetre.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$lab = Join-Path $root 'trellis_lab'
$comfy = Join-Path $lab 'ComfyUI'
$source = Join-Path $root 'inputs\mino_reference.png'
$destDir = Join-Path $comfy 'input'
$dest = Join-Path $destDir 'MINO_reference.png'
$url = 'http://127.0.0.1:8189/object_info'

Write-Host ''
Write-Host '========== MINO / VERIFICATION COMFTRELLIS ==========' -ForegroundColor Cyan
Write-Host ('Serveur : ' + $url)
try {
    $info = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 40
} catch {
    Write-Host 'ERREUR : impossible de joindre ComfyUI sur 127.0.0.1:8189.' -ForegroundColor Red
    Write-Host 'Garde ouvert le PowerShell qui execute lancer_comfyui_trellis.ps1.'
    throw
}

$names = @('LoadTrellisModel', 'TrellisInference', 'SaveGLBFile', 'RembgSquare', 'TrellisGrid')
$missing = @()
Write-Host ''
Write-Host '[1/3] Noeuds enregistres sur le serveur' -ForegroundColor Yellow
foreach ($name in $names) {
    $entry = $info.PSObject.Properties[$name]
    if ($null -eq $entry) {
        Write-Host ('ABSENT : ' + $name) -ForegroundColor Red
        $missing += $name
        continue
    }
    Write-Host ('OK : ' + $name) -ForegroundColor Green
    $required = $entry.Value.input.required
    if ($null -ne $required) {
        $requiredNames = @($required.PSObject.Properties | ForEach-Object { $_.Name })
        Write-Host ('   Champs requis : ' + ($requiredNames -join ', '))
    }
}
if ($missing.Count -gt 0) {
    Write-Host ('ERREUR : noeuds absents : ' + ($missing -join ', ')) -ForegroundColor Red
    Write-Host 'Envoie le journal du PowerShell de lancement ComfyUI, surtout les erreurs de custom_nodes.'
    exit 2
}
Write-Host 'MINO TRELLIS : TOUS LES NOEUDS PRESENTS' -ForegroundColor Green

Write-Host ''
Write-Host '[2/3] Preparation de l image de MINO' -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    Write-Host ('REFERENCE NON TROUVEE : ' + $source) -ForegroundColor Yellow
    Write-Host 'Le serveur est valide, mais nous devrons retrouver la reference avant le workflow.'
} else {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        $srcHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
        if ($srcHash -ne $dstHash) {
            Write-Host ('ATTENTION : ' + $dest + ' existe et est different. Aucun ecrasement.') -ForegroundColor Yellow
        } else {
            Write-Host 'Image MINO deja presente dans ComfyUI.'
        }
    } else {
        Copy-Item -LiteralPath $source -Destination $dest -ErrorAction Stop
        Write-Host ('Image copiee : ' + $dest) -ForegroundColor Green
    }
}

Write-Host ''
Write-Host '[3/3] Espace disque du lecteur local' -ForegroundColor Yellow
$drive = (Get-Item -LiteralPath $lab).PSDrive
if ($null -ne $drive -and $null -ne $drive.Free) {
    Write-Host ('Lecteur ' + $drive.Name + ' : ' + [math]::Round($drive.Free / 1GB, 1) + ' Go libres')
} else {
    Write-Host 'Espace disque indisponible avec cette methode.'
}

Write-Host ''
Write-Host '========== VERIFICATION TERMINEE ==========' -ForegroundColor Green
Write-Host 'Aucun modele TRELLIS charge ou telecharge.'
Write-Host 'Envoie-moi ce resultat pour choisir le workflow et preparer les poids.'
