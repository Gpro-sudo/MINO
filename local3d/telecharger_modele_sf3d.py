"""Telecharge les deux fichiers officiels Stable Fast 3D dans MINO/local3d/models.

Necessite que l'utilisateur ait obtenu acces au depot de poids sur Hugging Face
et se soit authentifie LOCALement avec huggingface-cli login.
N'affiche ni ne collecte de token et n'ecrit rien dans Git.
"""
from __future__ import annotations

import pathlib
import sys

from huggingface_hub import HfFolder, hf_hub_download
from huggingface_hub.utils import HfHubHTTPError

REPO = "stabilityai/stable-fast-3d"
FILES = ("config.yaml", "model.safetensors")


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent
    target = root / "models" / "stable-fast-3d"
    token = HfFolder.get_token()
    if not token:
        print("ERREUR : aucune authentification locale Hugging Face.")
        print(r"Lance : & '.\local3d\.venv-sf3d\Scripts\huggingface-cli.exe' login")
        print("Ne communique jamais ton token dans la conversation ou sur GitHub.")
        return 1
    target.mkdir(parents=True, exist_ok=True)
    print("Depot de poids :", REPO)
    print("Destination locale :", target)
    for filename in FILES:
        try:
            path = hf_hub_download(
                repo_id=REPO,
                filename=filename,
                local_dir=str(target),
                token=token,
            )
        except HfHubHTTPError as exc:
            print("ECHEC : acces aux poids refuse ou indisponible.")
            print("Verifier que l acces a https://huggingface.co/stabilityai/stable-fast-3d")
            print("a ete accepte pour le compte connecte, puis relancer.")
            print("Code de statut HTTP :", getattr(exc.response, "status_code", "?"))
            return 2
        except Exception as exc:
            print("ECHEC telechargement de", filename, type(exc).__name__, str(exc))
            return 3
        print("OK :", pathlib.Path(path).name, "-", round(pathlib.Path(path).stat().st_size / (1024**2)), "Mio")
    print("MINO SF3D : POIDS DU MODELE DISPONIBLES EN LOCAL")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
