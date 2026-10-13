"""Verification de la version CUDA reconnue par PyTorch sous Windows.

Evite les problemes d'echappement de guillemets dans PowerShell -c.
"""
import os
import sys

try:
    import numpy
    import torch
    from torch.utils.cpp_extension import CUDA_HOME

    print("PyTorch :", torch.__version__)
    print("CUDA embarquee dans PyTorch :", torch.version.cuda)
    print("GPU operationnel :", torch.cuda.is_available())
    print("CUDA_HOME vu par PyTorch :", CUDA_HOME)
    print("CUDA_HOME environment :", os.environ.get("CUDA_HOME"))
    print("NumPy :", numpy.__version__)
except Exception as exc:
    print("ECHEC diagnostic PyTorch :", repr(exc))
    sys.exit(1)
