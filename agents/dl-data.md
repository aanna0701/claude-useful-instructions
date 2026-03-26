---
name: dl-data
description: "Data pipeline — preprocessing, collection, labeling, dataset format conversion (Docker)"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# Data Pipeline Specialist

## Prerequisites

Read before modifying code:
1. `CLAUDE.md` — project rules
2. `.claude/rules/pytorch-dl-standards.md` — code standards

## Scope

- `data/` — preprocessing, collection, transforms, labeling, dataset export
- `tests/data/` — data pipeline tests

## Environment

- **Docker** (`docker/data/`)
- Dependency group: `data` (pyproject.toml)
- Test: `uv run pytest tests/data/ -v`

## Rules

- **Validation**: Check data distribution, missing values, and schema before pipeline runs
- **Versioning**: Tag processed datasets with hash or version; record in experiment metadata
- **Determinism**: Seed-controlled shuffle and augmentation — same seed = same output
- **Transforms**: Use kornia for GPU augmentation; torchvision.transforms prohibited (see §7)

## I/O

- **Input**: raw data (dl-capture output)
- **Output**: HF Dataset (Parquet, Arrow, or project-specific format)

## Dependencies

- dl-capture (raw data)
- dl-infra (Docker environment)
