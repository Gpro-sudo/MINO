"""Controle des extensions TRELLIS precompilees dans l'environnement Python isole.

Ce script teste uniquement les imports (sans executer l'inference).
"""
from __future__ import annotations

import importlib
import pathlib
import sys


def main() -> int:
    venv = pathlib.Path(__file__).resolve().parent / "trellis_lab" / ".venv"
    if not pathlib.Path(sys.executable).resolve().is_relative_to(venv.resolve()):
        print("ECHEC : Python execute hors du laboratoire TRELLIS :", sys.executable)
        return 2

    import torch
    if not torch.__version__.startswith("2.5.1+cu124"):
        print("ECHEC : PyTorch modifie :", torch.__version__)
        return 3
    if not torch.cuda.is_available():
        print("ECHEC : CUDA non disponible")
        return 4
    print("PyTorch :", torch.__version__, "| GPU :", torch.cuda.get_device_name(0))
    failed = []
    for mod_name in (
        "nvdiffrast",
        "nvdiffrast.torch",
        "vox2seq",
        "diff_gaussian_rasterization",
        "diffoctreerast",
        "utils3d",
    ):
        try:
            mod = importlib.import_module(mod_name)
            # Ne jamais faire getattr(mod, "__version__") : utils3d 0.0.2
            # essaie de charger utils3d.__version__ via son __getattr__ dynamique.
            print("OK :", mod_name, vars(mod).get("__version__", "(non declaree)"), flush=True)
        except Exception as exc:
            failed.append(mod_name)
            print("ECHEC :", mod_name, type(exc).__name__, str(exc), flush=True)

    if failed:
        print("Extensions non importables :", ", ".join(failed), flush=True)
        return 1
    print("MINO TRELLIS : EXTENSIONS NATIVES CHARGEES")
    print("Les noyaux GPU natifs, ComfyUI et la generation 3D restent encore a tester.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
