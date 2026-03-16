# 서브에이전트 설계 규칙

이 문서는 Phase 3에서 에이전트 구조를 설계할 때 참조한다.

---

## 핵심 규칙

### 규칙 1: 1 에이전트 = 1 단계
절대로 하나의 에이전트가 2개 단계를 담당하지 않는다.
이유: 실패 격리, 독립 테스트, 재실행 범위 최소화.

### 규칙 2: 에이전트 간 통신 = JSON manifest
DB나 메모리가 아니라 파일로 주고받는다.
이유: 디버깅 가능, 재현 가능, 사람이 읽을 수 있음.

manifest 형식:
```json
{
  "stage": "Stage 2: DB Indexing",
  "timestamp": "2026-03-15T14:30:00Z",
  "status": "completed",
  "processed": 45,
  "skipped": 3,
  "failed": 2,
  "errors": [
    {"session": "20260310_143000", "error": "frames.csv missing column: timestamp"}
  ],
  "output_path": "metadata/robot_inventory.duckdb"
}
```

### 규칙 3: 공통 인터페이스
모든 에이전트는 아래 인터페이스를 따른다:

```python
class BaseAgent:
    def run(self, config: dict) -> Report:
        """단계 실행. config에 입출력 경로, 옵션 포함."""
        ...

    def validate(self, data_path: str) -> ValidationReport:
        """출력 데이터 검증. 데이터를 수정하지 않음 (read-only)."""
        ...

@dataclass
class Report:
    processed: int
    skipped: int
    failed: int
    errors: list[dict]      # [{"item": "...", "error": "..."}]
    manifest_path: str       # 저장된 manifest 경로

@dataclass  
class ValidationReport:
    passed: bool
    checks: list[dict]       # [{"name": "...", "passed": bool, "message": "..."}]
```

### 규칙 4: Orchestrator는 조율만
순서 결정, gate 판단(통과/중단), 로그 기록만 수행한다.
비즈니스 로직은 절대 orchestrator에 넣지 않는다.

Orchestrator 판단 로직:
```
for stage in stages:
    report = stage.agent.run(config)
    validation = stage.agent.validate(stage.output_path)
    
    if not validation.passed:
        log_failure(stage, validation)
        if stage.is_blocking:  # 기본값: True
            abort_pipeline(validation)
        else:
            warn_and_continue(validation)
    
    save_manifest(stage, report)
```

---

## 공통 에이전트 상세

### Schema Validator

모든 프로젝트에 생성. 단계 간 입출력 계약을 코드로 강제한다.

역할:
- 각 단계 진입점에서 입력 데이터를 스키마로 validate
- Pydantic BaseModel로 계약 정의
- 실패 시 어떤 필드가 왜 실패했는지 명확한 에러 메시지

구현 위치: `data/contracts/`

프로젝트별 커스터마이징:
- 계약의 필드/타입은 프로젝트마다 다르지만, 구조는 동일
- 각 단계의 입력 스키마 + 출력 스키마를 Pydantic으로 정의
- validate_input(data, schema) → 통과 또는 상세 에러

### Quality Gate

모든 프로젝트에 생성. 최종 출력물의 통계적 품질을 검증한다.

역할:
- 데이터 통계 요약 (건수, 분포, 결측치 비율)
- 이상치 탐지 (IQR 기반 또는 도메인 룰)
- pass/fail 판정 + 상세 리포트

출력 형식:
```json
{
  "passed": true,
  "summary": {
    "total_records": 50000,
    "null_ratio": 0.002,
    "outlier_count": 12
  },
  "checks": [
    {"name": "null_ratio < 0.05", "passed": true, "value": 0.002},
    {"name": "outlier_ratio < 0.01", "passed": true, "value": 0.00024}
  ]
}
```

### Orchestrator

모든 프로젝트에 생성. 전체 파이프라인을 순차 실행한다.

CLI 인터페이스 (필수 지원):
```
--all              전체 파이프라인 실행
--stage N          특정 단계만 실행
--session ID       특정 세션/배치만 처리
--dry-run          실행 없이 처리 대상 미리보기
```

---

## 조건부 에이전트 상세

### Integrity Guard

생성 조건: raw/원본 데이터가 존재하는 프로젝트.

역할:
- seal: 파일 checksum 계산 → MANIFEST 기록 → read-only 권한 설정
- verify: MANIFEST와 실제 파일 비교 → 불일치 탐지
- ingest 완료 후 자동 seal 호출

### Lineage Tracker

생성 조건: transform 단계가 존재하여 원본-결과 매핑이 끊어질 수 있는 경우.

역할:
- 최종 출력의 각 레코드가 어떤 원본에서 왔는지 기록
- 순방향 추적: 출력 → 원본
- 역방향 추적: 원본 → 포함된 모든 출력
- CLI 유틸리티로 즉시 조회 가능

### Migration Manager

생성 조건: DB 스키마가 있고 진화할 가능성이 있는 경우.

역할:
- 스키마 변경 마이그레이션 스크립트 관리
- 각 마이그레이션에 롤백 스크립트 동반
- 트랜잭션 안에서 실행

### Deduplicator

생성 조건: 여러 소스에서 데이터가 합쳐지는 경우.

역할:
- 중복 탐지 (exact match + fuzzy match)
- 중복 해소 전략 (최신 우선, 소스 우선순위 등)
- 중복 리포트 생성

### Anonymizer

생성 조건: PII/민감정보가 포함된 데이터인 경우.

역할:
- PII 필드 식별 및 마스킹/해싱
- 원본과 익명화 데이터 간 매핑 테이블 (별도 보안 저장)
- 마스킹 정책 config로 관리

---

## 에이전트 수 가이드라인

프로젝트 규모에 따른 적정 에이전트 수:

| 규모 | 파이프라인 단계 | 에이전트 수 | 구성 |
|------|----------------|------------|------|
| 소규모 (1인, 단순 ETL) | 2~3 | 4~5 | 공통 3 + 단계별 1~2 |
| 중규모 (팀, 여러 소스) | 3~5 | 6~8 | 공통 3 + 단계별 + 조건부 1~2 |
| 대규모 (다팀, 복잡 변환) | 5+ | 8~12 | 공통 3 + 단계별 + 조건부 다수 |

에이전트가 12개를 넘으면 구조가 과잉 복잡해질 수 있다.
단계 자체를 합칠 수 있는지 먼저 검토할 것.
