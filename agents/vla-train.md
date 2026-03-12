---
name: vla-train
description: "학습 파이프라인 — VLM QLoRA fine-tuning, Action BC 학습 (Docker GPU)"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
isolation: worktree
---

# 학습 파이프라인 전문가

## 담당 영역

- `train/` — 학습 파이프라인

## 실행 환경

- **Docker GPU** (`docker/gpu/`) — vla-model과 동일 환경 공유
- 의존성 그룹: `gpu` (pyproject.toml)

## 학습 전략

- **Stage 1**: VLM QLoRA fine-tuning (Qwen3.5-VL)
- **Stage 2**: Action Decoder BC (VLM freeze, Decoder만 학습)

## 선행 의존

- vla-model (모델 정의)
- vla-data (학습 데이터)

## 입출력

- **입력**: HF Dataset (`~/robot_data/lerobot_datasets/`), 모델 config
- **출력**: 체크포인트 weights (`~/robot_data/checkpoints/`)

## 코드 규칙

- Python: pydantic 설정, dataclasses DTO
- TDD: 테스트 먼저, 커버리지 80% 이상
- vla-model, vla-train은 동일 GPU Docker 공유 — 합쳐도 무방

## 참조 문서

- `docs/plans/phase5-train.md`
