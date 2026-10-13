"""Test des premieres dependances TRELLIS sans charger le modele.

Ne demarre pas ComfyUI et n'execute aucune installation.
"""
from __future__ import annotations
import importlib
import sys

def main() -> int:
    failed = []
    for name in (
        "torch", "torchvision", "xformers",
        "numpy", "kaolin", "spconv", "easydict",
        "imageio", "trimesh", "xatlas", "pyvista",
        "plyfile", "pymeshfix", "igraph", "cv2",
        "rembg", "huggingface_hub"
    ):
        try:
            mod = importlib.import_module(name)
            version = getattr(mod, "__version__", "(version non exposee)")
            print(f"OK : {name} {version}", flush=True)
        except Exception as exc:
            failed.append(name)
            print(f"ECHEC : {name} : {type(exc).__name__}: {exc}", flush=True)
    if failed:
        print("Imports manquants :", ", ".join(failed))
        return 1

    import torch
    if not torch.__version__.startswith("2.5.1+cu124"):
        print("ECHEC : mauvaise version PyTorch :", torch.__version__)
        return 2
    if not torch.cuda.is_available():
        print("ECHEC : CUDA n'est plus disponible.")
        return 3
    print("GPU :", torch.cuda.get_device_name(0))
    print("MINO TRELLIS : BIBLIOTHEQUES DE BASE DISPONIBLES")
    print("Attention : nvdiffrast/vox2seq/rasteriseurs et ComfyUI non encore testes.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
