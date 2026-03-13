# VasInt 코드 표준

이 파일은 모든 에이전트(메인/서브)가 반드시 따라야 하는 코드 규칙이다.
서브에이전트는 코드 수정 전 이 파일을 반드시 Read해야 한다.

## 1. 설정값 vs 내부 DTO

### pydantic BaseModel — 외부 입력을 받는 설정 클래스

YAML, CLI, API 요청 등 외부 데이터를 파싱하는 클래스는 반드시 pydantic을 사용한다.
수동 검증 코드를 작성하지 마라 — pydantic이 자동으로 처리한다.

```python
# CORRECT: 외부 YAML 입력 → pydantic
from pydantic import BaseModel, Field

class RobotConfig(BaseModel, frozen=True):
    robot_id: str
    column_map: dict[str, str]
    description: str = ""

# 로드 시 검증 자동
config = RobotConfig(**yaml.safe_load(open("config.yaml")))
```

```python
# WRONG: 외부 입력에 dataclass + 수동 검증
@dataclass
class RobotConfig:
    robot_id: str
    column_map: dict[str, str]

def load_config(path):
    data = yaml.safe_load(open(path))
    if not data.get("robot_id"):        # 이런 수동 검증 금지
        raise ValueError("Missing robot_id")
    ...
```

### dataclass — 내부 DTO (모듈 간 데이터 전달)

외부 입력 없이 코드 내부에서만 생성/전달되는 객체는 dataclass를 사용한다.

```python
# CORRECT: 내부 전용 DTO → dataclass
from dataclasses import dataclass

@dataclass(frozen=True)
class StateRegion:
    start_idx: int
    end_idx: int
    state: int
```

### 판단 기준

| 데이터 출처 | 사용할 것 | 이유 |
|------------|----------|------|
| YAML/JSON 파일 | `pydantic BaseModel` | 타입 강제 변환 + 검증 |
| CLI 인자 | `pydantic BaseModel` | 입력값 검증 |
| API 요청/응답 | `pydantic BaseModel` | 직렬화 + 검증 |
| 함수 간 전달 | `@dataclass(frozen=True)` | 가벼움, 검증 불필요 |
| DB 쿼리 결과 래핑 | `@dataclass(frozen=True)` | 가벼움 |

## 2. 불변 객체 패턴

모든 데이터 클래스는 불변이어야 한다:
- pydantic: `class Config(BaseModel, frozen=True)`
- dataclass: `@dataclass(frozen=True)`

원본을 수정하지 말고 새 객체를 반환하라:

```python
# CORRECT
new_config = config.model_copy(update={"robot_id": "v2"})  # pydantic
new_region = replace(region, state=9)                       # dataclass

# WRONG
config.robot_id = "v2"  # frozen이면 에러, 아니면 사이드이펙트
```

## 3. 파일/함수 크기 제한

- 파일당 800줄 이하
- 함수당 50줄 이하
- 초과 시 분리하라

## 4. 테스트 (TDD)

- 구현 전 테스트를 먼저 작성 (RED → GREEN → REFACTOR)
- 커버리지 80% 이상
- `uv run pytest` 으로 실행 (pip 금지)

## 5. 의존성 관리

- Python 패키지는 `uv`로만 관리 (`pip install` 금지)
- 새 의존성 추가 순서: `docs/TECH_STACK.md` → 해당 `docs/stack/*.md` → `pyproject.toml`
- pydantic은 이미 `host` 그룹에 포함됨 (`pydantic>=2.0`)

## 6. 에러 처리

- 에러를 삼키지 마라 (bare `except:` 금지)
- 시스템 경계(외부 입력, 파일 I/O, API)에서 검증하라
- 내부 코드는 타입을 믿어라 (과도한 방어 코딩 금지)

## 7. Import 순서

```python
# 1. 표준 라이브러리
from __future__ import annotations
import json
from pathlib import Path

# 2. 서드파티
import numpy as np
import pandas as pd
from pydantic import BaseModel

# 3. 프로젝트 내부
from data.collection.config import RobotConfig
```
