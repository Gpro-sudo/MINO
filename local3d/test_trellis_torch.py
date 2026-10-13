"""Test GPU isole pour PyTorch 2.5.1 / CUDA 12.4 / xformers.

Ne charge pas TRELLIS et ne change aucun paquet.
"""
from __future__ import annotations

import sys


def main() -> int:
    try:
        import torch
        import torchvision
        import xformers
        import xformers.ops
    except Exception as exc:
        print("ECHEC IMPORT :", type(exc).__name__, str(exc))
        return 1

    print("Python :", sys.version.split()[0])
    print("PyTorch :", torch.__version__)
    print("Torchvision :", torchvision.__version__)
    print("xformers :", xformers.__version__)
    print("CUDA PyTorch :", torch.version.cuda)

    if not torch.__version__.startswith("2.5.1"):
        print("ECHEC : PyTorch 2.5.1 attendu.")
        return 2
    if torch.version.cuda != "12.4":
        print("ECHEC : roues PyTorch CUDA 12.4 attendues.")
        return 3
    if not torch.cuda.is_available():
        print("ECHEC : CUDA non disponible dans le laboratoire TRELLIS.")
        return 4

    print("GPU :", torch.cuda.get_device_name(0))
    print("VRAM totale :", round(torch.cuda.get_device_properties(0).total_memory / 1024**2), "Mio")
    x = torch.tensor([2.0, 3.0], device="cuda")
    answer = (x * x).sum().item()
    print("Calcul GPU :", answer, "(attendu 13.0)")
    if answer != 13.0:
        print("ECHEC calcul CUDA.")
        return 5

    try:
        import xformers.ops as xops

        q = torch.randn((1, 16, 1, 64), device="cuda", dtype=torch.float16)
        k = torch.randn((1, 16, 1, 64), device="cuda", dtype=torch.float16)
        v = torch.randn((1, 16, 1, 64), device="cuda", dtype=torch.float16)
        result = xops.memory_efficient_attention(q, k, v)
        torch.cuda.synchronize()
        print("xformers CUDA :", tuple(result.shape))
    except Exception as exc:
        print("ECHEC TEST XFORMERS :", type(exc).__name__, str(exc))
        return 6

    print("MINO TRELLIS : PYTORCH ET XFORMERS GPU OPERATIONNELS")
    print("Attention : TRELLIS lui-meme n'est pas encore installe ni valide.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
