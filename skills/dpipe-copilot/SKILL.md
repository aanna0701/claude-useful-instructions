---
name: dpipe-copilot
description: >
  데이터 파이프라인 운영(operations) 스킬. 이미 구축된 데이터 파이프라인
  (data indexing → dataset construction → derived artifacts) 의
  실행/검증/재생성/장애대응을 다룬다. Docker + DuckDB/Parquet + 비디오 인코딩
  (NVENC 등) 기반 파이프라인에서 자주 발생하는 함정(스키마 drift, 의존성
  변경 후 이미지 미리빌드, 컨테이너 in-memory 코드 stale, 파생물 재생성 순서)을
  체크리스트로 제공한다.
  "파이프라인 다시 돌려줘", "dpipe 실행", "스테이지 검증", "파생물 재생성",
  "DuckDB 스키마 확인", "cropped_videos 재생성", "encoder 출력 검증",
  "viewer/container 갱신", "pipeline operations", "run dataset pipeline" 등의
  요청에 트리거. 설계(design) 작업은 sibling skill `data-pipeline-architect`를
  사용할 것.
---

# dpipe Operations

이미 만들어진 데이터 파이프라인을 **굴리는 동안** 필요한 운영 지식.
구조 설계는 `data-pipeline-architect`를 쓰고, 여기는 그 다음 단계 — 실행/검증/장애대응만 다룬다.

## When to Activate

- 사용자가 파이프라인 스테이지를 돌려달라고 할 때 (`dpipe run`, `run stage X`)
- 이전 스테이지 출력 검증을 요청할 때 (DuckDB row count, parquet schema, mp4 count)
- 설정 변경(인코더, crop geometry, frame_sync 윈도우)으로 파생물 재생성이 필요할 때
- 파이프라인 컨테이너/뷰어가 stale, 의존성 변경 후 동작 이상이 보일 때
- DuckDB/parquet schema drift 의심 (`Table X does not have a column named Y`)

## 일반화된 스테이지 모델

대부분의 로봇/멀티모달 데이터 파이프라인은 아래 3 layer로 환원된다:

```
[layer A] data_indexing
    save raw → DB(예: DuckDB) + archive(예: NAS/S3)
                          │
                          ▼
[layer B] dataset_construction
    frame_sync → window_videos → cropped_videos → cropped_images
                          │
                          ▼
[layer C] labeling / training_input
    rule-based label → analyzer → writer → text labels in DB
```

스테이지 이름은 프로젝트마다 다르지만 **의존성 방향**은 거의 항상 동일하다:
indexing → construction → derived video/image → labeling.

## Invariants (Universal)

1. **Schema drift = 즉시 실패**
   - 한 단계가 DB에 컬럼을 추가했는데 다른 단계의 로컬 DB 인스턴스가 그 컬럼을 모르면 파이프라인 멈춤.
   - 증상: `Table "..." does not have a column named "..."`.
   - 처방: 마이그레이션 스크립트로 컬럼 동기화 OR 로컬 DB drop & rebuild.

2. **Reproducibility는 코드가 아니라 환경에 산다**
   - 시드, CUDA determinism, dataloader shuffle 시드, 정확한 lib 버전(pyproject 고정), Docker 이미지 — 모두 외부 설정으로 빠져 있어야 한다.
   - 학습 루프 안에 하이퍼파라미터 하드코딩 금지.

3. **재생성 순서는 단방향**
   - 상류 산출물의 mtime / config hash 가 바뀌면 모든 하류는 stale.
   - 절대 중간 단계부터 시작하지 말 것. 입력이 정확히 동일함을 증명 못 하면 상류부터 다시.

## Docker + Container 라이프사이클 (자주 까먹는 것)

- **dep 변경 → 이미지 rebuild 필수.**
  `pyproject.toml` / `requirements.txt` 가 변하면 이미지가 `uv sync` / `pip install` 결과를 캐시하고 있으므로, rebuild 없이는 새 lib이 컨테이너 안에 없다.
  ```bash
  docker compose build <service>
  ```

- **Python 코드 변경 → 실행 중 컨테이너 restart 필수.**
  뷰어/대시보드/MJPEG 프리뷰처럼 장시간 떠 있는 Python 컨테이너는 코드를 **메모리에 들고 있다**. 파일만 수정하고 끝나면 옛 코드가 계속 응답한다.
  ```bash
  docker restart <container-name>
  ```

- **터널은 운영 외 영역.** 포트 포워딩이 안 되면 일단 컨테이너 안에서 직접 curl 해서 서비스 자체는 살아있는지 먼저 확인.

## 검증 체크리스트 (스테이지별 일반형)

| 스테이지 | 확인 |
|---|---|
| 원본 저장 (indexing) | DB 테이블 존재 / row count > 0 / 필수 컬럼 누락 없음 / archive stamp 생성 / 로컬 DB 보존(archive로 대체 X) |
| 시간 동기화 (frame_sync) | 윈도우 수 == 프레임 인덱스 파일 수 / 타임스탬프 gap 없음 |
| 비디오 생성 (window/cropped videos) | 윈도우 수 == mp4 수 / `ffprobe` 로 codec·preset·rate-control 일치 / 해상도 == crop geometry |
| 이미지 추출 (cropped images) | 윈도우당 jpg 수 == frame count / 샘플 1장 정상 open |
| 라벨링 | DB 라벨 컬럼 채워짐 / 룰 dispatch 결과 분포 sanity check |

도구: `duckdb -readonly` (DB inspect) · `ffprobe` (비디오 sanity) · `find ... | wc -l` (개수) · 샘플 1장 `feh` / `imgcat`.

## 재생성 의사결정 트리

```
설정 변경 발생
  └─ 어떤 단계의 입력에 영향? ──────┐
                                  │
   인덱싱 입력(원본 데이터)?  ────▶ 전체 재실행
   frame_sync 윈도우 정의? ──────▶ frame_sync 부터 재실행
   인코더 설정?            ──────▶ window_videos + cropped_videos 재실행
   crop geometry?         ──────▶ cropped_videos + cropped_images 재실행
   라벨 룰?              ──────▶ 라벨링만 재실행
```

원칙: **위에서부터 끊고, 그 아래는 무조건 다시.**

## 공통 실패 모드

| 증상 | 가능 원인 | 처방 |
|---|---|---|
| `Table X does not have column Y` | 로컬 DB 스키마가 한 단계 뒤처짐 | 컬럼 추가 마이그레이션 or DB rebuild |
| 뷰어가 옛날 프레임을 보여줌 | 컨테이너가 이전 코드 메모리 보유 | 컨테이너 restart |
| 컨테이너 안에서 `ModuleNotFoundError` | dep 변경 후 이미지 rebuild 안 됨 | `docker compose build` 재실행 |
| ffprobe codec mismatch | 인코더 설정 바꾼 뒤 video 미재생성 | window/cropped videos 재생성 |
| 윈도우당 frame count 불일치 | frame_sync 결과와 cropped 미스매치 | frame_sync 부터 전체 재실행 |
| 두 세션이 동시에 작업하면 worktree 충돌 | 병렬 AI 세션 race | 한쪽은 직접 commit 으로 우회 |

## Subagent Delegation

스테이지 실행과 출력 검증은 long-running + log-heavy 작업이라 메인 컨텍스트를 더럽힌다. 이 스킬은 **`dpipe-runner`** agent에게 위임하도록 권장한다:

> "이번 스테이지는 dpipe-runner agent에게 맡길게요. 구조화된 PASS/FAIL 리포트만 받아옵니다."

agent 호출 시 항상 알려주어야 하는 것:
- 실행할 컨테이너 / 서비스 이름
- 활성 job config 파일 경로
- 대상 DB 파일 경로 (있다면)
- 검증할 산출물 디렉터리 (window_videos/, cropped_videos/, …)
- 이 프로젝트의 main 브랜치 이름 (절대 그 위에서 실행 금지)

## Hard Limits

- 로컬 DB 를 **명시적 확인 없이 삭제 금지**. archive 가 있어도 undo 가 아니다.
- 기본 브랜치(main 등) 위에서 파이프라인을 실행하지 말 것 — 작업 브랜치/worktree 에서만.
- pre-commit / CI `--no-verify` 우회 금지.
- 학습 코드 / `pyproject.toml` 수정은 이 스킬의 범위 밖. 상위 에이전트로 위임.

## 관련 자산

- 설계: `data-pipeline-architect` (sibling skill)
- 실행 agent: `dpipe-runner` (sibling agent)
- 워크플로우 표준: `collab-workflow` (work item 생성/리뷰)
