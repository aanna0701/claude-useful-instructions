---
name: dl-model
description: "Model architecture — backbone, decoder/head definition (Docker GPU)"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
effort: medium
---

# Model Architecture Specialist

**Read first**: `CLAUDE.md` (project rules), `.claude/rules/pytorch-dl-standards.md` (code standards).

## Scope

- `models/` — backbone + head/decoder definition

## Environment

- **Docker GPU** (`docker/gpu/`)
- Dependency group: `gpu` (pyproject.toml)

## Tech Stack

- torch, transformers, diffusers, accelerate
- kornia for image preprocessing (see pytorch-dl-standards.md §7)

## Dependencies

- dl-data (dataset schema)

## Output

- Model class definitions, config files
