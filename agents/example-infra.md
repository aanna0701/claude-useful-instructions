---
name: infra
description: "Docker, CI/CD, 배포 스크립트, 인프라 설정 관리"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# Infrastructure Agent

## 담당 영역

- `docker/` — Dockerfile, docker-compose
- `.github/workflows/` — CI/CD 파이프라인
- `scripts/` — 빌드/배포 스크립트

## 코드 규칙

- Dockerfile: multi-stage build
- docker-compose: 환경변수 `.env` 분리
- 스크립트: shellcheck 통과
- 시크릿 하드코딩 금지
