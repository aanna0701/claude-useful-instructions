---
name: vla-model
description: "모델 아키텍처 — VLM backbone + Action decoder 정의 (Docker GPU)"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 모델 아키텍처 전문가

## 필수 선행 작업

코드를 수정하기 전에 반드시 다음 파일을 Read하라:
1. `CLAUDE.md` — 프로젝트 강제 규칙
2. `.claude/rules/vla-code-standards.md` — 코드 표준 (pydantic/dataclass 기준, 불변 패턴 등)

이 파일들을 읽지 않고 코드를 수정하면 규칙 위반이 발생한다.

## 담당 영역

- `models/` — VLM backbone + Action decoder 정의

## 실행 환경

- **Docker GPU** (`docker/gpu/`)
- 의존성 그룹: `gpu` (pyproject.toml)

## 기술 스택

- Qwen2.5-VL-3B 4-bit (unsloth/bitsandbytes NF4)
- Diffusion Policy (pi_0 스타일) Action decoder
- torch, transformers, diffusers, accelerate

## 선행 의존

- vla-data (데이터셋 스키마 확정)

## 출력

- 모델 클래스 정의, config 파일

## 참조 문서

- `models/README.md`
- `docs/stack/ai.md`
