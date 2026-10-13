"""Controle du ComfyUI isole apres installation (aucun modele IA charge).

Verifier les versions et les imports de base, sans demarrer le serveur et sans
importer ComfTrellis (__init__.py contient une routine tierce d'installation).
"""
from __future__ import annotations

import os
from pathlib import Path
import sys


def main() -> int:
    root = Path(__file__).resolve().parent
    lab = root / "trellis_lab"
    comfy = lab / "ComfyUI"
    venv = lab / ".venv"

    if not Path(sys.executable).resolve().is_relative_to(venv.resolve()):
        print("ECHEC : interpreter Python different du labo :", sys.executable)
        return 2

    sys.path.insert(0, str(comfy))
    os.environ.setdefault("ATTN_BACKEND", "xformers")
    os.environ.setdefault("SPCONV_ALGO", "native")

    failed = []
    for name in (
        "torch", "torchvision", "torchaudio", "xformers",
        "transformers", "huggingface_hub", "safetensors",
        "aiohttp", "yaml", "folder_paths", "comfy.model_management",
    ):
        try:
            mod = __import__(name, fromlist=["*"])
            version = vars(mod).get("__version__", "(non declaree)")
            print("OK :", name, version, flush=True)
        except Exception as exc:
            failed.append(name)
            print("ECHEC :", name, type(exc).__name__, str(exc), flush=True)

    if failed:
        print("Imports manquants :", ", ".join(failed), flush=True)
        return 1

    import torch
    import transformers
    import huggingface_hub

    if torch.__version__ != "2.5.1+cu124":
        print("ECHEC : mauvaise version de PyTorch :", torch.__version__)
        return 3
    if transformers.__version__ != "4.48.3":
        print("ECHEC : version Transformers inattendue :", transformers.__version__)
        return 4
    if huggingface_hub.__version__ != "0.34.4":
        print("ECHEC : version Hugging Face inattendue :", huggingface_hub.__version__)
        return 5
    if not torch.cuda.is_available():
        print("ECHEC : GPU CUDA indisponible")
        return 6
    print("GPU :", torch.cuda.get_device_name(0))
    print("MINO TRELLIS : COMFYUI ISOLE PRET POUR DEMARRAGE")
    print("TRELLIS, ses poids et la VRAM en inference n'ont pas encore ete testes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
