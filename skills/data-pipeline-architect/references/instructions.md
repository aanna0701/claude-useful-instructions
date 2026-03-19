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
10. Orchestrator           (1~9 전체 조립)
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

## 카테고리별 Instruction 작성 가이드

### Schema Contract 계열
- 입력: 현재 코드에서 암묵적으로 가정하는 스키마
- 출력: Pydantic BaseModel 또는 JSON Schema로 명시적 계약
- 핵심: validate 실패 시 상세 에러 메시지 (어떤 필드, 왜)
- 주의: 기존 데이터 형태를 먼저 파악하고, 그에 맞는 스키마를 작성할 것

### Integrity 계열
- 핵심 함수: seal(checksum 기록 + 권한 변경), verify(checksum 비교)
- 주의: seal은 ingest 완료 후에만, verify는 read-only
- idempotent: 이미 sealed된 것을 다시 seal해도 안전

### Migration 계열
- 반드시 트랜잭션 안에서 실행
- 롤백 스크립트 동반 필수
- 마이그레이션 전후 데이터 건수 일치 검증

### Lineage 계열
- batch insert로 성능 유지
- 순방향 + 역방향 조회 CLI 제공
- 기존 테이블 수정하지 않고 별도 테이블

### Validation 계열
- validator는 데이터를 절대 수정하지 않음 (read-only)
- 복합 실패 시 모든 실패를 한 번에 리포트 (첫 실패에서 중단하지 않음)
- 전체 이미지 디코딩 같은 무거운 검증은 피할 것

### Idempotent 계열
- progress tracker로 완료된 항목 스킵
- UPSERT로 중복 삽입 방지
- 같은 입력 → 같은 결과 보장

### Dead Letter Queue 계열
- DLQ 디렉토리/테이블 구조 정의 (record, stage, error, timestamp)
- 격리 시 원본 단계와 실패 사유를 반드시 기록
- 재처리 CLI: 수정 후 재투입 또는 영구 폐기
- DLQ 적재량 모니터링: 임계값 초과 시 파이프라인 경고
- 핵심: 비정상 데이터가 정상 흐름을 오염시키지 않도록 격리

### Atomicity 계열
- Staging area: 임시 공간에서 처리 완료 후 atomic rename/swap으로 최종 반영
- DB 작업은 트랜잭션으로 묶기 (부분 커밋 방지)
- Checkpointing: 장시간 배치는 진행 상태를 주기적으로 기록
- 장애 복구 시 마지막 체크포인트부터 재시작
- Write-Audit-Publish 패턴: staging 쓰기 → 검증 → 통과 시 publish

### Audit & Observability 계열
- 각 단계에서 입력/출력/스킵/에러 건수 기록
- Count reconciliation: input == output + skipped + error 자동 검증
- 처리 시간, 처리량(throughput) 기록
- Health check: latency 임계값 초과 또는 에러율 급증 시 경고
- 배치 간 통계 비교: 이전 대비 급격한 분포 변화 탐지

### Quality Validation 계열
- Null check: 필수 필드 NULL 비율이 임계값 이하인지 검증
- Range & format check: 숫자 범위, 날짜 형식, 문자열 패턴 검증
- Consistency check: 외래키 관계, 비즈니스 룰 일관성 검증
- Distribution check: 이전 배치 대비 통계적 분포 변화 탐지
- 핵심: 스키마는 통과하지만 내용이 비정상인 데이터를 잡아낼 것

### Orchestrator 계열
- thin wrapper: 각 단계 모듈을 import해서 호출만
- CLI 지원: --all, --stage N, --session ID, --dry-run
- 실행 로그 타임스탬프별 저장

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
