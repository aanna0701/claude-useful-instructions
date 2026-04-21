---
name: dl-train
description: "Training pipeline — fine-tuning, distributed training (Docker GPU)"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
effort: medium
---

# Training Specialist

**Read first**: `CLAUDE.md` (project rules), `.claude/rules/pytorch-dl-standards.md` (code standards).

## Scope

- `train/` — training pipeline

## Environment

- **Docker GPU** (`docker/gpu/`) — shares environment with dl-model
- Dependency group: `gpu` (pyproject.toml)

## Capabilities

- QLoRA / LoRA fine-tuning
- Multi-stage training (backbone freeze → head training)
- Distributed training via Accelerate

## Rules

- **Seed**: `accelerate.utils.set_seed()` + cudnn deterministic at script entry (see §8)
- **Checkpoint**: `accelerator.save_state()` for full state (model + optimizer + scheduler + step)
- **Resume**: Every training script must accept `--resume <checkpoint_dir>`
- **Profiling**: Check for I/O bottleneck (data loading vs GPU compute) before scaling up
- **Logging**: WandB run for every experiment — params, metrics, git hash (see §9)

## Dependencies

- dl-model (model definition)
- dl-data (training data)

## I/O

- **Input**: HF Dataset, model config
- **Output**: checkpoints (safetensors), WandB run
