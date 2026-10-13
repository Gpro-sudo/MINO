# MINO — diagnostic non destructif de ComfyUI lance par Pinokio.
# N'installe rien et ne modifie ni Pinokio ni son environnement Python.
$ErrorActionPreference = 'Continue'

Write-Host '========== MINO / DIAGNOSTIC COMFYUI POUR TRELLIS ==========' -ForegroundColor Cyan
Write-Host 'ComfyUI doit rester ouvert dans Pinokio pendant le diagnostic.'
Write-Host ''

$procs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.Name -match '^(python|pythonw)(\.exe)?$') -and
        ($_.CommandLine -match '(?i)ComfyUI|(?:^|\s|[\\/])main\.py(?:\s|["'']|$)')
    })
if ($procs.Count -eq 0) {
    Write-Host '[INFO] Aucun processus Python ComfyUI trouve automatiquement.' -ForegroundColor Yellow
    Write-Host 'Ouvre la console ou les Logs dans Pinokio, puis copie les lignes :'
    Write-Host 'Python executable / Python version / pytorch version / ComfyUI Path.'
    exit 0
}

$uniqueExe = @($procs | ForEach-Object { $_.ExecutablePath } |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -Unique)

Write-Host ('[1] Processus ComfyUI trouves : ' + $procs.Count) -ForegroundColor Yellow
foreach ($proc in $procs) {
    Write-Host ('PID : ' + $proc.ProcessId)
    Write-Host ('Python executable : ' + $proc.ExecutablePath)
    # Ne pas afficher CommandLine brute : elle pourrait contenir des parametres personnels.
}

foreach ($exe in $uniqueExe) {
    Write-Host ''
    Write-Host ('[2] Interpreter Python : ' + $exe) -ForegroundColor Yellow
    & $exe --version
    Write-Host 'Paquet torch installe dans cet interpreteur :'
    & $exe -m pip show torch 2>$null | Where-Object { $_ -match '^(Name|Version|Location):' }
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[INFO] pip show torch non disponible dans cet interpreteur.'
    }
}

Write-Host ''
Write-Host '[3] Carte graphique' -ForegroundColor Yellow
$nv = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
if ($nv) {
    & $nv.Source --query-gpu=name,memory.total,memory.free --format=csv,noheader
}

Write-Host ''
Write-Host 'DIAGNOSTIC TERMINE : aucune modification.' -ForegroundColor Green
Write-Host 'Envoie-moi ce resultat ; je choisirai une version TRELLIS compatible.'
