"""Diagnostic lecture seule des versions CUDA utilisees par TRELLIS."""
from __future__ import annotations

import sys
import torch
from torch.utils import cpp_extension

print("Python :", sys.executable)
print("PyTorch :", torch.__version__)
print("CUDA PyTorch :", torch.version.cuda)
print("CUDA_HOME PyTorch :", cpp_extension.CUDA_HOME)
print("GPU disponible :", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU :", torch.cuda.get_device_name(0))
