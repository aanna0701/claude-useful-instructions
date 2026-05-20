---
name: dpipe-copilot
description: >
  데이터 파이프라인 운영(operations) 스킬. 이미 구축된 데이터 파이프라인의
  실행 / 검증 / 재생성 / 장애대응을 다룬다. Docker + 컬럼 스토어(DuckDB / Parquet /
  SQLite 등) + 파일 산출물(이미지/오디오/비디오/텍스트) 기반 파이프라인에서 자주
  발생하는 함정 — 스키마 drift, dep 변경 후 이미지 미빌드, 장수명 컨테이너의
  in-memory 코드 stale, 파생물 재생성 순서 — 을 일반화된 체크리스트로 제공한다.
  "파이프라인 다시 돌려줘", "스테이지 검증", "파생물 재생성", "DB 스키마 확인",
  "산출물 재생성", "컨테이너 갱신", "pipeline operations", "rerun stage",
  "verify pipeline outputs", "regenerate derived artifacts", "schema drift" 등의
  요청에 트리거. 설계(design) 단계는 sibling skill `data-pipeline-architect`를
  쓸 것 — 이 스킬은 그 다음, 즉 이미 만들어진 파이프라인을 굴리는 시기에 동작.
---

# dpipe Operations

이미 만들어진 데이터 파이프라인을 **굴리는 동안** 필요한 운영 지식.
구조 설계는 `data-pipeline-architect`, 여기는 그 다음 단계 — 실행 / 검증 / 장애대응만 다룬다.

## When to Activate

- 사용자가 파이프라인 스테이지를 실행해달라고 할 때 (`run stage X`, "이 단계 다시")
- 이전 스테이지 출력을 검증해달라고 할 때 (DB row count, 스키마, 파일 개수, sample inspect)
- 설정 변경(인코더/파라미터/윈도우 정의/룰)으로 파생물 재생성이 필요할 때
- 장수명 컨테이너(viewer / dashboard / inference server)가 stale, dep 변경 후 동작 이상
- 스키마 drift 의심 (`Table X does not have a column named Y` 등)

## 일반화된 스테이지 모델

대부분의 운영 파이프라인은 **3 layer + 의존성 방향 1개**로 환원된다:

```
[layer A] indexing
    원본 입력 → 마스터 DB + (optional) 영구 archive
                          │
                          ▼
[layer B] construction / derivation
    원본 → 파생 산출물 (전처리/세그먼트/feature/window 등)
                          │
                          ▼
[layer C] labeling / training_input / serving_input
    파생 산출물 → 라벨 / feature store / 추론 입력
```

스테이지 이름은 프로젝트마다 다르지만 **의존성 방향은 한 방향**: indexing → derivation → labeling/serving.
역방향 재실행 또는 중간 단계만 재실행은 거의 항상 함정.

## Invariants (Universal)

1. **Schema drift = 즉시 실패**
   - 한 단계가 DB에 컬럼/필드를 추가했는데 다른 단계의 인스턴스가 이를 모르면 파이프라인 멈춤.
   - 증상: `Table "..." does not have a column named "..."`, `KeyError: 'new_field'`, parquet 읽기 시 missing column.
   - 처방: 마이그레이션 스크립트로 스키마 동기화 OR 로컬 데이터스토어 drop & rebuild (`/archive` 가 있다면 거기서).

2. **Reproducibility는 코드가 아니라 환경에 산다**
   - 시드, 결정론 플래그(예: CUDA determinism), 데이터로더 셔플 시드, lib 버전 고정(`pyproject.toml` / `requirements.txt` / lockfile), Docker 이미지 — 모두 외부 설정으로 분리.
   - 실행 루프 안에 하이퍼파라미터/경로 하드코딩 금지.

3. **재생성 순서는 단방향**
   - 상류 산출물의 mtime / config hash 가 바뀌면 모든 하류는 stale.
   - 절대 중간 단계부터 시작하지 말 것. 입력이 정확히 동일함을 증명 못 하면 상류부터 다시.

## Docker + Container 라이프사이클 (자주 까먹는 것)

- **dep 변경 → 이미지 rebuild 필수.**
  `pyproject.toml` / `requirements.txt` / `package.json` 이 변하면 이미지가 의존성 설치 결과를 캐시하고 있으므로, rebuild 없이는 새 lib이 컨테이너 안에 없다.
  ```bash
  docker compose build <service>
  ```

- **소스 변경 → 실행 중 컨테이너 restart 필수.**
  뷰어 / 대시보드 / 추론 서버 / 프리뷰 같은 **장수명** 컨테이너는 코드를 메모리에 들고 있다. 파일만 수정하고 끝나면 옛 코드가 계속 응답한다.
  ```bash
  docker restart <container-name>
  ```
  (CLI 실행처럼 매 호출마다 새 프로세스를 띄우는 컨테이너는 해당 없음.)

- **터널은 운영 외 영역.** 포트 포워딩이 안 되면 일단 컨테이너 안에서 직접 `curl` / `nc` 로 서비스 자체가 살아있는지 먼저 확인.

## 검증 체크리스트 (스테이지별 일반형)

| 스테이지 종류 | 확인 |
|---|---|
| 원본 indexing | 마스터 테이블/콜렉션 존재 · row 또는 doc count > 0 · 필수 필드 누락 없음 · archive stamp 생성 · 로컬 데이터스토어 보존 |
| 시간/공간 정렬 (sync) | 그룹 수 == 인덱스 파일 수 · 키 gap 없음 · 정렬 키 단조성 |
| 파생 파일 생성 (segment / clip / chunk) | 그룹 수 == 산출 파일 수 · 메타데이터(코덱/해상도/길이/샘플레이트 등) 일치 · 파일 0 byte 없음 |
| 추출 / 샘플링 (frame / token / row) | 그룹당 개수 == 사양 · 샘플 1건 정상 open · 무결성 hash 일치 |
| 라벨링 / annotation | 라벨 컬럼 채움률 · 분포 sanity (단일 클래스 쏠림/NaN/null) · 룰 dispatch 분포 점검 |

공통 도구 패턴:
- DB inspect: `duckdb -readonly` / `sqlite3 -readonly` / `psql -c '\d+ <table>'`
- 컨테이너 메타 점검: `ffprobe` / `mediainfo` (미디어), `parquet-tools show` / `pyarrow.parquet` (parquet), `jq` (JSON)
- 개수: `find ... | wc -l`, `ls -1 | wc -l`
- 샘플 inspect: `feh` / `imgcat` (이미지), `mpv --no-config` (비디오), `head -c 1024 | xxd` (바이너리)

## 재생성 의사결정 트리

```
설정 변경 발생
  └─ 어떤 단계의 입력에 영향? ────────┐
                                    │
   indexing 입력(원본 데이터/스키마)? ────▶ 전체 재실행 (가장 비용 큼)
   sync / 그룹 정의?                ────▶ sync 부터 하류 전체
   파생 파일 생성 파라미터?         ────▶ 파생 파일 + 그 이하 모두
   추출/샘플 파라미터?              ────▶ 추출 + 그 이하 모두
   라벨/annotation 룰?              ────▶ 라벨링만 재실행
```

원칙: **위에서부터 끊고, 그 아래는 무조건 다시.**
판단 기준은 *"이 설정이 산출물 한 비트라도 바꾸는가"*. 바꾸면 stale.

## 공통 실패 모드

| 증상 | 가능 원인 | 처방 |
|---|---|---|
| `Table X does not have column Y` / parquet missing column | 로컬 DB/스키마가 한 단계 뒤처짐 | 마이그레이션 OR drop & rebuild |
| 뷰어 / 대시보드가 옛 결과를 보여줌 | 장수명 컨테이너가 이전 코드 메모리 보유 | `docker restart <container>` |
| 컨테이너 안에서 `ModuleNotFoundError` / `cannot find package` | dep 변경 후 이미지 rebuild 누락 | `docker compose build <service>` |
| 파생 파일 메타(코덱/샘플레이트/스키마)가 새 설정과 불일치 | 설정 바꾼 뒤 재생성 안 함 | 의사결정 트리 따라 상류부터 재실행 |
| 그룹당 개수가 사양과 다름 | sync 산출과 하류 미스매치 | sync 부터 전체 재실행 |
| 두 세션이 동시에 작업하면 worktree 충돌 | 병렬 AI 세션 race | 한쪽은 직접 commit 으로 우회 |
| `--no-verify` 로 pre-commit 우회한 채 머지됨 | 인간 또는 AI 의 단축 행동 | 별도 commit 으로 lint/format 강제 적용 |

## Subagent Delegation

스테이지 실행과 출력 검증은 long-running + log-heavy 작업이라 메인 컨텍스트를 더럽힌다. 이 스킬은 **`dpipe-runner`** agent에게 위임할 것을 권장한다:

> "이번 스테이지는 dpipe-runner agent 에게 맡길게요. 구조화된 PASS/FAIL 리포트만 받아옵니다."

agent 호출 시 항상 제공해야 하는 컨텍스트(프로젝트마다 다름):

- 실행 환경: 컨테이너 / 서비스 이름, docker compose 파일 경로
- 활성 설정 파일 경로
- 대상 데이터스토어 경로 (DB 파일 / 스키마)
- 검증할 산출물 디렉터리 목록
- 이 프로젝트의 기본 브랜치 이름 (그 위에서 직접 실행 금지)
- 재실행 시 시작 스테이지와 그 근거 (재생성 의사결정 트리에서 도출)

## Hard Limits

- 로컬 데이터스토어를 **명시적 확인 없이 삭제 금지**. archive 가 있어도 undo 가 아니다 (생성 비용/순서가 비대칭).
- 기본 브랜치(main 등) 위에서 파이프라인 실행 금지 — 작업 브랜치/worktree 에서만.
- pre-commit / CI `--no-verify` 우회 금지.
- 모델 학습 코드 / 의존성 매니페스트(`pyproject.toml` 등) 수정은 이 스킬 범위 밖. 적절한 상위 에이전트로 위임.
- 산출물 디렉터리(`window_*/`, `cropped_*/`, `segments/` 등 프로젝트별 이름)를 임의 이름으로 rename / restructure 하지 말 것 — 하류 단계 모두 stale.

## 관련 자산

- 설계: `data-pipeline-architect` (sibling skill)
- 실행 agent: `dpipe-runner` (sibling agent)
- 워크플로우 표준: `collab-workflow` (work item 생성/리뷰)
