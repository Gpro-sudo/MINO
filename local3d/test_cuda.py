"""Verifie localement le chargement PyTorch et un calcul sur GPU NVIDIA."""
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
except Exception as error:
    print("MINO CUDA : TEST ECHEC -", repr(error))
    sys.exit(1)
