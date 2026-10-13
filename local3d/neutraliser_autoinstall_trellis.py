"""MINO: neutraliser l'installation automatique de ComfTrellis dans le labo isole.

Le node importe setup_packages() au chargement et peut executer pip automatiquement.
Ce patch empeche uniquement cet appel dans la copie locale, SANS demarrer le node
et SANS toucher a Pinokio. Les imports du node restent testes par ComfyUI au demarrage.
"""
from pathlib import Path

root = Path(__file__).resolve().parent
node = root / "trellis_lab" / "ComfyUI" / "custom_nodes" / "ComfTrellis" / "__init__.py"
if not node.exists():
    raise SystemExit("ERREUR : ComfTrellis introuvable ; lance preparer_trellis_isole.ps1.")

source = node.read_text(encoding="utf-8")
original = 'if setup_packages():'
replacement = (
    '# MINO LAB ONLY: installation automatique desactivee.\n'
    '# Les dependances sont installees separement dans .venv.\n'
    'if True:'
)
if replacement in source:
    print("MINO : installation automatique deja neutralisee.")
elif source.count(original) == 1:
    node.write_text(source.replace(original, replacement, 1), encoding="utf-8")
    print("MINO : installation automatique neutralisee dans la copie locale de ComfTrellis.")
else:
    raise SystemExit("ERREUR : structure inattendue de __init__.py ; aucun fichier modifie.")

print("ComfyUI Pinokio et GitHub restent inchanges.")
