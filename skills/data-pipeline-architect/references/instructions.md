# Instruction 생성 규칙

이 문서는 Phase 4에서 Claude Code instruction 세트를 생성할 때 참조한다.

---

## 생성 규칙

### 규칙 1: 독립 완료 가능
각 instruction은 다른 instruction 없이도 단독으로 완료·테스트·merge 가능해야 한다.
단, 의존성이 있으면 순서를 명시한다.

### 규칙 2: 필수 섹션
모든 instruction에 반드시 포함:

```
# 목표
한 문장. "무엇을 왜."

# 배경
현재 상태 + 왜 문제인지. 2~3문장.

# 해야 할 것
1. [구체적 작업]
2. [구체적 작업]
3. [구체적 작업]

# 테스트
- [정상 케이스]: 기대대로 동작하는 시나리오
- [비정상 케이스]: 잘못된 입력에 대해 올바른 에러 처리
- [경계 케이스]: 빈 데이터, 단일 레코드, 최대 크기 등

# 제약
- 기존 코드 동작을 바꾸지 말 것
- [프로젝트 특화 제약]
```

### 규칙 3: 기존 코드 보호
"기존 코드 동작을 바꾸지 말 것"을 기본 제약으로 항상 넣는다.
새 레이어를 추가하는 방식으로 개선한다.
기존 테스트가 깨지면 안 된다.

### 규칙 4: 의존성 그래프 순서
아래 순서를 기본으로 하되, 프로젝트에 해당하지 않는 것은 건너뛴다:

```
1. Schema Contract         (모든 후속 작업의 기반)
2. Integrity Guard         (raw 보호, 이후 변경 감지에 활용)
3. Schema Migration        (DB 구조 개선, contract 위에서)
4. Dead Letter Queue       (비정상 데이터 격리, contract 위에서)
5. Lineage Tracker         (transform 추적, contract + integrity 활용)
6. Audit & Observability   (건수 reconciliation + health check)
7. Quality Validation      (null/range/consistency 검증, contract 위에서)
8. Atomicity & Checkpoint  (staging area, 트랜잭션, 체크포인트)
9. Idempotent Execution    (재실행 안전성, integrity + checkpoint 활용)
10. Parallelism            (각 단계의 병렬 처리 적용, 모든 단계 구현 후)
11. Orchestrator           (1~10 전체 조립, 독립 단계 병렬 실행 포함)
```

의존성이 없는 것들은 병렬 가능하다고 명시한다.
예: 2(Integrity), 3(Migration), 4(DLQ)는 서로 독립적이므로 병렬 가능.
예: 6(Audit), 7(Quality), 8(Atomicity)도 서로 독립적이므로 병렬 가능.

### 규칙 5: @멘션 가이드
각 instruction 앞에 관련 파일 @멘션 가이드를 넣는다:
```
> 관련 파일: `@data/collection/ingest.py` `@data/contracts/schemas.py`
> 이 파일들을 함께 보여주세요.
```

### 규칙 6: 테스트 최소 3개
각 instruction에 테스트가 3개 미만이면 추가한다.
테스트는 정상/비정상/경계 세 종류를 반드시 포함한다.

---

## Instruction 템플릿

아래 템플릿을 기반으로 프로젝트 특화 내용을 채워 넣는다:

````markdown
## Instruction N: [제목]

> 선행 조건: Instruction [X], [Y] 완료
> 관련 파일: `@path/to/file1.py` `@path/to/file2.py`

```
# 목표
[한 문장으로 "무엇을 왜"]

# 배경
[현재 상태. 무엇이 문제인지. 2~3문장.]

# 해야 할 것
1. [디렉토리/모듈 생성]
2. [핵심 함수/클래스 구현]
3. [기존 코드와 연결]
4. [문서 업데이트]

# 테스트
- 정상: [기대대로 동작하는 시나리오]
- 비정상: [잘못된 입력 → 올바른 에러 처리]
- 경계: [빈 데이터, 단일 레코드, 최대 크기 등]

# 제약
- 기존 코드 동작을 바꾸지 말 것
- [프로젝트 특화 제약 1]
- [프로젝트 특화 제약 2]
```
````

---

## 카테고리별 Instruction 작성 힌트

> 각 카테고리의 원칙 상세는 `reliability.md`, 에이전트 상세는 `agents.md`, 병렬화 상세는 `parallelism.md` 참조.
> 여기서는 **instruction 작성 시에만 필요한 추가 힌트**만 기록한다.

| 카테고리 | 작성 시 핵심 힌트 |
|----------|------------------|
| Schema Contract | 기존 데이터 형태를 먼저 파악 → Pydantic으로 명시적 계약. validate 실패 시 상세 에러 (어떤 필드, 왜) |
| Integrity | seal은 ingest 완료 후에만, verify는 read-only. 이미 sealed된 것을 다시 seal해도 안전 |
| Migration | 트랜잭션 필수, 롤백 스크립트 동반, 전후 건수 일치 검증 |
| Lineage | batch insert로 성능 유지, 기존 테이블 수정 금지 (별도 테이블), 순방향+역방향 CLI |
| Validation | read-only (데이터 수정 금지), 복합 실패 시 모든 실패를 한 번에 리포트, 무거운 검증(이미지 디코딩 등) 지양 |
| DLQ | 재처리 CLI 제공 (재투입 or 영구 폐기), 적재량 모니터링 포함 |
| Atomicity | Write-Audit-Publish 패턴: staging → 검증 → publish |
| Parallelism | 상세 규칙: `parallelism.md`. 핵심: 순수 함수 + DLQ 연동 에러 핸들링 |
| Orchestrator | thin wrapper, CLI: --all/--stage/--session/--dry-run/--workers/--sequential, DAG 기반 inter-stage 병렬 |

---

## 사용 가이드 (최종 출력에 포함)

instruction 세트와 함께 아래 사용 가이드를 반드시 포함:

```markdown
## 사용 가이드

### 순서
1 → 2 → ... 순서대로, 하나씩 진행하세요.
각 instruction이 완료·테스트·merge된 후 다음으로.

### Claude Code에 줄 때
1. 관련 파일을 @멘션으로 함께 보여주세요
2. "테스트를 먼저 작성하고, 그 테스트를 통과하도록 구현해줘"라고 하면 더 견고
3. 한 번에 instruction 하나만 주세요

### 프로젝트 컨텍스트
Claude Code 세션 시작 시 아래를 붙여넣으세요:
[프로젝트별 컨텍스트 블록 — Phase 0 정보 기반으로 자동 생성]
```
