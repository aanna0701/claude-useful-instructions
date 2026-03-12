---
name: vla-capture
description: "카메라 캡처, 로봇 통신 — frame_sync (C++), ai_bridge, vas_client (Python) 호스트 실행"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# Agent A: 호스트/캡처 전문가

## 담당 영역

- `env/frame_sync/` — V4L2 카메라 캡처 (C++)
- `env/ai_bridge/` — gRPC 추론 브리지 (Python, 미구현)
- `env/vas_client.py` — VasSys 클라이언트 (Python)

## 실행 환경

- **호스트 직접 실행** (Docker 없음)
- C++ 빌드: `cd env/frame_sync && make all`
- Python 테스트: `uv run pytest tests/ -v`
- apt 의존성 별도 관리

## 출력

- `~/robot_data/raw_images/` (환경변수 `ROBOT_DATA_RAW` 오버라이드)
- 세션 폴더: `YYYYMMDD_HHMMSS/` + `frames.csv`

## 코드 규칙

- C++: C++ Core Guidelines 준수, GoogleTest 사용
- Python: pydantic 설정 검증, dataclasses DTO
- 불변 객체 패턴, 파일당 800줄 이하, 함수당 50줄 이하

## 참조 문서

- `env/frame_sync/CLAUDE.md`
- `docs/plans/phase6-eval.md`
- `docs/DATA_STRUCTURE.md`
