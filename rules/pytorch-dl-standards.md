# PyTorch DL Code Standards

> Extends coding-style.md for PyTorch-based deep learning projects.

## 1. Config vs DTO

| Source | Use | Why |
|--------|-----|-----|
| YAML/JSON/CLI/API | `pydantic BaseModel(frozen=True)` | Auto validation + type coercion |
| Internal transfer | `@dataclass(frozen=True)` | Lightweight, no validation needed |

```python
# External input → pydantic
class TrainConfig(BaseModel, frozen=True):
    lr: float = 3e-4
    batch_size: int = 32

# Internal DTO → dataclass
@dataclass(frozen=True)
class StepResult:
    loss: float
    step: int
```

## 2. Immutability (Python)

- pydantic: `BaseModel(frozen=True)` + `model_copy(update={...})`
- dataclass: `@dataclass(frozen=True)` + `replace(obj, field=val)`

## 3. Testing

- TDD: RED → GREEN → REFACTOR
- Coverage 80%+
- Run: `uv run pytest`

## 4. Dependencies

- `uv` only (`pip install` prohibited)
- Add order: `docs/TECH_STACK.md` → `docs/stack/*.md` → `pyproject.toml`

## 5. Error Handling

- No bare `except:` — always specify exception type
- Trust internal types (no excessive defensive coding)

## 6. Import Order

```python
# 1. stdlib
from pathlib import Path

# 2. third-party
import torch
from pydantic import BaseModel

# 3. project
from models.backbone import VLMBackbone
```

## 7. DL Tech Stack

Default packages by stage. Changes or additions require user approval first.

| Stage | Packages |
|-------|----------|
| Core / Acceleration | PyTorch, Accelerate, Unsloth, Flash-Attention |
| Data / Processing | Datasets, Kornia |
| Eval / Logging | Torchmetrics, WandB |
| Storage | Safetensors |

### Image Transforms

Use `kornia` for GPU image preprocessing. `torchvision.transforms` is prohibited in training/eval pipelines.

```python
# CORRECT — GPU batch transform (differentiable)
import kornia.augmentation as K
transform = K.AugmentationSequential(
    K.Resize((224, 224)),
    K.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
)

# WRONG — CPU, non-differentiable
from torchvision import transforms  # prohibited
```

CPU-only scripts (data collection, quick visualization) may use `Pillow`.

## 8. Reproducibility

Every training run must be deterministic and reproducible.

- **Seed**: Call `accelerate.utils.set_seed(seed)` at the top of every entry point
- **CUDA determinism**: Set `torch.backends.cudnn.deterministic = True` and `benchmark = False`
- **Data ordering**: Seed-controlled shuffle in DataLoader; deterministic augmentation pipelines
- **Config as Code**: All hyperparameters in YAML/pydantic config — never hardcode in training loops
- **Environment pinning**: Exact library versions in `pyproject.toml`; Docker for CUDA version matching

## 9. Experiment Tracking

No experiment exists without a record.

- **WandB mandatory**: Log params, metrics, hardware stats, and git commit hash for every run
- **Checkpoint**: Save full state (`accelerator.save_state()`) — model, optimizer, scheduler, epoch, step
- **Resume**: Every training script must support `--resume <checkpoint_dir>` for mid-run recovery
- **Artifact versioning**: Tag data snapshots (hash or version) in experiment metadata
