---
name: vla-capture
description: "카메라 캡처, 로봇 통신 — frame_sync (C++), ai_bridge, vas_client (Python) 호스트 실행"
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 호스트/캡처 전문가

## 필수 선행 작업

코드를 수정하기 전에 반드시 다음 파일을 Read하라:
1. `CLAUDE.md` — 프로젝트 강제 규칙
2. `.claude/rules/vla-code-standards.md` — 코드 표준 (pydantic/dataclass 기준, 불변 패턴 등)
3. `env/frame_sync/CLAUDE.md` — frame_sync 전용 규칙

이 파일들을 읽지 않고 코드를 수정하면 규칙 위반이 발생한다.

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

## 참조 문서

- `env/frame_sync/CLAUDE.md`
- `docs/DATA_STRUCTURE.md`
