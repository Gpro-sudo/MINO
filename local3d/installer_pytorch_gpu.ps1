# MINO — installation PyTorch 2.4.1 CUDA 12.1 dans le SEUL venv local SF3D.
# N'installe pas le CUDA Toolkit systeme et ne touche ni a Blender ni a Python global.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$python = Join-Path $PSScriptRoot '.venv-sf3d\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    Write-Host '[MINO] Environnement introuvable. Lance d abord preparer_sf3d.ps1.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '========== MINO - INSTALLATION PYTORCH GPU ==========' -ForegroundColor Cyan
Write-Host ('Python isole : ' + $python)
& $python -c "import sys,struct;assert sys.version_info[:2]==(3,11) and struct.calcsize('P')==8, 'Python 3.11 64 bits attendu';print('Python',sys.version.split()[0],'64 bits OK')"
if ($LASTEXITCODE -ne 0) { exit 2 }

Write-Host ''
Write-Host 'Etape 1 : installation des roues officielles PyTorch 2.4.1 / CUDA 12.1.' -ForegroundColor Cyan
Write-Host 'Le telechargement peut durer plusieurs minutes. Ne ferme pas cette fenetre.'
& $python -m pip install --disable-pip-version-check --prefer-binary 'torch==2.4.1' 'torchvision==0.19.1' --index-url 'https://download.pytorch.org/whl/cu121'
if ($LASTEXITCODE -ne 0) {
    Write-Host '[MINO] Installation interrompue. Envoie-moi les dernieres lignes de pip.' -ForegroundColor Red
    exit 3
}

Write-Host ''
Write-Host 'Etape 2 : verification du calcul GPU CUDA (une petite operation seulement).' -ForegroundColor Cyan
$check = @'
import sys
try:
    import torch
    import torchvision
    print("PyTorch :", torch.__version__)
    print("Torchvision :", torchvision.__version__)
    print("CUDA de PyTorch :", torch.version.cuda)
    if not torch.cuda.is_available():
        raise RuntimeError("PyTorch ne detecte pas CUDA. Arret avant Stable Fast 3D.")
    print("GPU :", torch.cuda.get_device_name(0))
    x = torch.tensor([2.0, 3.0], device="cuda")
    y = (x * x).sum()
    torch.cuda.synchronize()
    print("Test GPU :", y.item(), "(attendu : 13.0)")
    if y.item() != 13.0:
        raise RuntimeError("Resultat GPU incorrect")
    print("MINO CUDA : TEST REUSSI")
except Exception as e:
    print("MINO CUDA : TEST ECHEC -", repr(e))
    sys.exit(1)
'@
& $python -c $check
if ($LASTEXITCODE -ne 0) {
    Write-Host '[MINO] PyTorch installe, mais CUDA doit etre corrige avant de poursuivre.' -ForegroundColor Red
    exit 4
}
Write-Host ''
Write-Host '[MINO] PyTorch GPU operationnel. Ne pas encore installer Stable Fast 3D.' -ForegroundColor Green
Write-Host 'Envoie-moi la sortie : nous preparerons CUDA Toolkit et les extensions Windows.'
exit 0
