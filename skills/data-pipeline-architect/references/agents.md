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

### 규칙 3: 공통 인터페이스 (병렬 처리 내장)
모든 에이전트는 아래 인터페이스를 따른다.
`run()` 내부에서 병렬화 가능하면 자동으로 병렬 실행한다.

```python
class BaseAgent:
    def run(self, config: dict) -> Report: ...          # 단계 실행. 병렬화 가능 시 자동 병렬.
    def validate(self, data_path: str) -> ValidationReport: ...  # 출력 데이터 검증. read-only.
    def process_item(self, item) -> Any: ...             # 개별 항목 처리 (병렬 단위)

@dataclass
class Report:
    processed: int; skipped: int; failed: int
    errors: list[dict]       # [{"item": "...", "error": "..."}]
    manifest_path: str

@dataclass
class ValidationReport:
    passed: bool
    checks: list[dict]       # [{"name": "...", "passed": bool, "message": "..."}]
```

병렬화 핵심: `_run_parallel`은 `ProcessPoolExecutor`(CPU bound) 또는 `ThreadPoolExecutor`(IO bound)를 자동 선택. 상세 규칙: `parallelism.md` 참조.

### 규칙 4: Orchestrator는 조율만
순서 결정, gate 판단(통과/중단), 로그 기록만 수행한다.
비즈니스 로직은 절대 orchestrator에 넣지 않는다.
**독립적인 단계는 반드시 병렬로 실행한다** (의존성 그래프 기반).

실행 흐름: dependency graph → topological batches → 배치 내 병렬 `asyncio.gather` → 각 stage 후 `validate()` → blocking stage 실패 시 abort, 아니면 warn & continue → manifest 저장.

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

모든 프로젝트에 생성. 의존성 그래프 기반으로 파이프라인을 실행한다 (독립 단계 병렬).

CLI 인터페이스 (필수 지원):
```
--all              전체 파이프라인 실행
--stage N          특정 단계만 실행
--session ID       특정 세션/배치만 처리
--dry-run          실행 없이 처리 대상 미리보기
--workers N        intra-stage 병렬 워커 수 (기본: min(cpu_count, 8))
--sequential       병렬 실행 비활성화 (디버깅용)
```

---

## 조건부 에이전트 상세

| Agent | 생성 조건 | 역할 | 핵심 기능 | 구현 위치 |
|-------|----------|------|----------|----------|
| **Integrity Guard** | raw/원본 데이터가 존재 | 파일 무결성 보장 | seal (checksum → MANIFEST → read-only), verify (MANIFEST vs 실제 비교), ingest 후 auto-seal | `data/integrity/` |
| **Lineage Tracker** | transform 단계에서 원본-결과 매핑이 끊어질 수 있음 | 데이터 계보 추적 | 순방향 추적 (출력→원본), 역방향 추적 (원본→모든 출력), CLI 조회 | `data/lineage/` |
| **Migration Manager** | DB 스키마가 있고 진화 가능성 있음 | 스키마 마이그레이션 관리 | 마이그레이션 스크립트 관리, 롤백 스크립트 동반, 트랜잭션 내 실행 | `data/migrations/` |
| **Deduplicator** | 여러 소스에서 데이터가 합쳐짐 | 중복 제거 | exact/fuzzy match 탐지, 해소 전략 (최신/소스 우선순위), 중복 리포트 | `data/dedup/` |
| **Anonymizer** | PII/민감정보 포함 데이터 | 개인정보 보호 | PII 필드 마스킹/해싱, 매핑 테이블 (별도 보안 저장), 마스킹 정책 config | `data/anonymize/` |
| **Dead Letter Handler** | 스키마 위반/비정상 데이터 유입, 파이프라인 중단 없이 격리 필요 | 실패 레코드 격리 | DLQ 디렉토리/테이블로 격리, 재처리 CLI (재투입/폐기), 적재량 모니터링 | `data/dlq/` |
| **Checkpoint Manager** | 장시간 배치/스트리밍에서 중간 장애 복구 필요 | 처리 진행 상태 관리 | 주기적 상태 기록 (offset, batch_id), 마지막 체크포인트부터 재시작, atomic write, 오래된 체크포인트 자동 삭제 | `data/checkpoints/` |
| **Audit Logger** | 단계 간 건수 reconciliation, 처리 이력 추적, 운영 가시성 필요 | 처리 이력 및 정합성 검증 | count reconciliation (`in == out + skip + err`), 처리 시간/처리량 기록, 에러율 급증 경고, 배치 간 통계 비교 | `data/audit/` |

### 데이터 계약 (조건부 에이전트)

```python
@dataclass(frozen=True)
class DeadLetter:
    record: dict; stage: str; error: str; timestamp: str; source_path: str

@dataclass(frozen=True)
class Checkpoint:
    stage: str; batch_id: str; last_offset: int
    status: str             # "in_progress" | "completed" | "failed"
    timestamp: str; metadata: dict

@dataclass(frozen=True)
class AuditRecord:
    stage: str; batch_id: str
    input_count: int; output_count: int; skipped_count: int; error_count: int
    duration_seconds: float; timestamp: str
    reconciled: bool        # input == output + skipped + error
```

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
