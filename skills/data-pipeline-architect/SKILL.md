---
name: data-pipeline-architect
description: >
  데이터 파이프라인 구조 설계 및 서브에이전트 자동 생성 스킬.
  사용자가 대략적인 데이터 구조(테이블, 파일, 파이프라인 흐름)를 주면
  8개 불변 원칙으로 진단하고, 프로젝트에 맞는 서브에이전트 구조와
  Claude Code instruction 세트를 자동 생성한다.
  "데이터 파이프라인 설계해줘", "데이터 구조 리뷰해줘", "파이프라인 에이전트 만들어줘",
  "데이터 설계 검토", "ETL 구조 잡아줘", "data pipeline", "데이터 아키텍처",
  "서브에이전트 구성", "데이터 수집-변환-적재 설계" 등의 요청에 트리거.
  데이터 관련 프로젝트에서 구조 설계나 파이프라인 자동화 이야기가 나오면 이 스킬을 사용할 것.
---

# Data Pipeline Architect

사용자의 데이터 구조 초안을 받아 → 원칙 기반 진단 → 서브에이전트 설계 → instruction 세트 생성까지 수행하는 스킬.

```
[사용자 입력]  →  Phase 1: 진단        →  Phase 2: 단계 식별  →  Phase 3: 에이전트 설계  →  Phase 4: Instruction 생성
                  (8원칙 + 5신뢰성)      (경계 도출)              (공통+조건부)              (순서+의존성)
```

---

## Required Reading

Read before each phase:
- Phase 1: `references/principles.md`, `references/reliability.md`
- Phase 2: `references/parallelism.md`
- Phase 3: `references/agents.md`
- Phase 4: `references/instructions.md`

## 워크플로우

### Phase 0: 입력 수집

사용자에게 확인 (이미 대화에 포함된 정보는 다시 묻지 말 것):

**필수:** 데이터 흐름 개요 (어디서→어디로), 각 단계 입출력 형태, 최종 목적

**선택:** 코드베이스 구조, 데이터 볼륨, 팀 규모, 알려진 문제점

---

### Phase 1: 구조 + 신뢰성 진단

사용자의 데이터 구조와 파이프라인을 두 가지 축으로 진단한다:
1. **구조 진단 (8원칙)**: 데이터 모델링의 정확성
2. **신뢰성 진단 (5원칙)**: 파이프라인 실행의 무결성과 복원력

각 원칙에 대해 **통과 ✅ / 위반 ⚠️ / 해당없음 —** 으로 판정하고,
위반 시 **위치 + 이유 + 처방**을 구체적으로 명시한다.

**출력 형식:**

```markdown
## 구조 진단 결과 (8원칙)

| # | 원칙 | 판정 | 위반 위치 | 처방 |
|---|------|------|-----------|------|
| 1 | Single Source of Truth | ⚠️ | user + order에 중복 email | order에서 제거, FK로 참조 |
| 2 | 의미의 단일성 | ✅ | - | - |
| ... | ... | ... | ... | ... |

## 파이프라인 신뢰성 진단 (5원칙)

| # | 원칙 | 판정 | 위험 구간 | 처방 |
|---|------|------|-----------|------|
| R1 | 멱등성 | ⚠️ | Stage 2 INSERT only | UPSERT로 변경, progress tracker 추가 |
| R2 | 데이터 계약 | ⚠️ | Stage 1→2 경계 | DLQ 추가, 스키마 버전 관리 |
| R3 | 원자성 | ✅ | - | - |
| R4 | 가시성 | ⚠️ | 전체 | audit log + count reconciliation 추가 |
| R5 | 품질 검증 | ⚠️ | Stage 3 출력 | null check + range check 추가 |

### 종합 소견
[2~3문장으로 구조와 신뢰성 양쪽의 강점과 핵심 개선 포인트 요약]
```

위반이 0개여도 진단표는 반드시 출력한다 (전부 ✅이면 사용자에게 신뢰감을 준다).

---

### Phase 2: 파이프라인 단계 식별

사용자의 데이터 흐름에서 자연스러운 **단계 경계**를 찾는다.

**경계 식별 규칙 (3가지 신호):**
1. **형태 변환**: 데이터 포맷이 바뀌는 지점 (이미지→CSV, CSV→DB, DB→Parquet)
2. **소유권 전환**: 실행 환경이 바뀌는 지점 (하드웨어→소프트웨어, 로컬→클라우드)
3. **비가역 지점**: 되돌리기 비용이 큰 지점 (raw 삭제, 집계 후 원본 소실)

각 단계마다 아래를 정의:

```yaml
stage: "Stage N: [이름]"
input:  { source: "...", format: "...", contract: "..." }
output: { target: "...", format: "...", contract: "..." }
invariants:
  - "이 단계가 반드시 보장하는 조건"
failure_mode: "실패 시 복구 전략"
idempotent: true/false  # 재실행 시 동일 결과 보장 여부
atomicity: "staging + rename / transaction / checkpoint"  # 원자성 확보 방식
dlq: true/false  # 비정상 데이터 격리 필요 여부
quality_checks:  # 출력 품질 검증 항목
  - "null_ratio < 0.05"
  - "value_range: 0~150"
parallelism:  # see references/parallelism.md for full schema
  intra_stage: { applicable, type, unit, shared_state, pattern }
  inter_stage: { independent_of, depends_on }
  data_parallelism: { applicable, partition_key }
```

---

### Phase 3: 서브에이전트 설계

**핵심 규칙:**
- 1 에이전트 = 1 단계. 예외 없음
- 에이전트 간 통신 = JSON manifest 파일
- 공통 인터페이스: `run(config) → Report`, `validate(path) → ValidationReport`
- Orchestrator는 조율만, 비즈니스 로직 금지
- 병렬화 가능한 단계는 Orchestrator가 동시 실행 (dependency graph 기반)

**공통 에이전트** (모든 프로젝트에 생성):
| 에이전트 | 역할 |
|----------|------|
| Schema Validator | 단계 간 입출력 계약 검증 |
| Quality Gate | 최종 출력물 통계 품질 검증 |
| Orchestrator | 의존성 그래프 기반 실행 (독립 단계 병렬) + gate 판단 + 로그 |

**조건부 에이전트** (프로젝트 특성에 따라 생성; for full specifications, see agents.md):
| 에이전트 | 생성 조건 |
|----------|-----------|
| Integrity Guard | raw/원본 데이터가 존재하는 경우 |
| Lineage Tracker | transform으로 원본-결과 매핑이 끊어지는 경우 |
| Migration Manager | DB 스키마가 진화 가능성이 있는 경우 |
| Deduplicator | 여러 소스 데이터가 합쳐지는 경우 |
| Anonymizer | PII/민감정보가 포함된 경우 |
| Dead Letter Handler | 스키마 위반/비정상 데이터 격리가 필요한 경우 |
| Checkpoint Manager | 장시간 배치/스트리밍에서 중간 상태 복구가 필요한 경우 |
| Audit Logger | 단계 간 건수 reconciliation 및 처리 이력 추적이 필요한 경우 |

**출력 형식:**

```
Orchestrator
├── Agent 1: [이름] — [역할 한 줄]
│   입력: ...  출력: ...  검증: ...
├── Agent 2: [이름] — [역할 한 줄]
│   ...
└── Agent N: Quality Gate — 최종 품질 리포트
```

---

### Phase 4: Instruction 세트 생성

**핵심 규칙:**
- 각 instruction은 독립적으로 완료·테스트·merge 가능
- 순서는 의존성 그래프로 결정
- 기본 제약: "기존 코드 동작을 바꾸지 말 것"

**각 instruction에 반드시 포함:**
```
# 목표      — 한 문장
# 배경      — 현재 상태 + 왜 문제인지
# 해야 할 것 — 구체적 작업 번호 목록
# 테스트    — 최소 3개 (정상/비정상/경계)
# 제약      — 하면 안 되는 것
```

---

### Phase 5: 자기 검증

instruction 세트 완성 후, 아래 체크리스트를 반드시 실행한다.
하나라도 미충족이면 해당 항목을 충족하는 추가 instruction을 생성한다.

```
# 구조 원칙 (8원칙)
□ All 8 structure principles reflected in at least 1 instruction (see principles.md)
□ Schema contracts exist at all stage boundaries
□ Raw data immutability guaranteed (if applicable)

# 신뢰성 원칙 (5원칙)
□ All 5 reliability principles met (see reliability.md): idempotency, data contracts/DLQ, atomicity, observability, quality validation
□ Scalability: validation logic does not become a bottleneck

# 병렬화
□ All parallelism criteria met (see parallelism.md): stage analysis, executor types, pure functions, inter-stage parallelism, DLQ integration, configurable num_workers

# 공통
□ instruction 간 순환 의존이 없는가?
□ 각 instruction의 테스트가 3개 이상인가?
```

검증 결과를 사용자에게 표로 보여주고, 전부 ✅이면 최종 결과를 출력한다.

---

## 최종 출력물

모든 Phase가 완료되면, 아래를 **하나의 markdown 파일**로 정리해서 전달한다:

1. 진단표 (Phase 1)
2. 파이프라인 단계 정의 (Phase 2)
3. 에이전트 구조도 (Phase 3)
4. Instruction 세트 전문 (Phase 4)
5. 검증 체크리스트 (Phase 5)
6. 사용 가이드 (순서, @멘션 팁, 테스트 우선 권장)

파일은 `{project_name}_pipeline_instructions.md`로 저장한다.

---

## 참고 사항

- 사용자가 "진단만 해줘"라고 하면 Phase 1만 실행
- "에이전트 구조만 보여줘"라면 Phase 1~3까지만
- "instruction까지 다 만들어줘"라면 Phase 1~5 전체
- 사용자의 기술 수준에 맞춰 용어 설명 수준을 조절할 것
