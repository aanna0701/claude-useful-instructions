---
name: codebase-qa
description: >
  GitNexus 기반 코드베이스 질의응답 스킬.
  "이 함수 바꾸면 뭐가 깨져?", "이 API 어떻게 흘러가?", "인증 처리하는 코드 다 찾아줘",
  "이 심볼 누가 쓰냐?", "이 커밋 영향 범위 알려줘", "모듈 구조 설명해줘",
  "where is X defined", "impact of removing Y", "how does request flow through Z",
  "who calls", "who depends on", "blast radius", "call graph",
  "코드베이스 질문", "codebase question" 등의 요청에 트리거.
  단순 질의는 직접 처리, 복합/다단계 질의는 codebase-researcher 에이전트로 위임.
---

# Codebase QA

GitNexus MCP를 활용해 코드베이스 질문에 답한다. 코드를 **수정하지 않는다**. 결과는 `file:line` 앵커로 고정된 증거 기반 답변.

```
[질문] → Phase 1: 전처리 → Phase 2: 분류 → Phase 3: 실행 → Phase 4: 답변
         (repo/index 확인)   (intent 맵핑)   (직접 or 위임)   (file:line + 요약)
```

---

## Phase 1: 전처리 (인덱스 freshness preflight)

**목표:** 단일 턴에서 `미인덱싱 / stale / fresh` 3상태를 판정하고, 필요 시 사용자 확인 후 재인덱싱.

### 1-a. 병렬 preflight (한 메시지에서 동시 호출)

다음 3개를 **반드시 병렬**로:

- `mcp__gitnexus__list_repos` — indexed repo 목록 + last analyzed timestamp.
- `mcp__gitnexus__group_status` — group 단위 stale 여부 (indexed일 때만 의미 있음, 실패해도 무시).
- `Bash`: `git -C <repo> rev-parse HEAD && git -C <repo> log -1 --format=%ct HEAD` — 현재 HEAD SHA + commit timestamp.

### 1-b. 상태 판정

| 상태 | 조건 |
|---|---|
| **not-indexed** | `list_repos` 결과에 현재 repo 없음 |
| **stale** | indexed이지만 다음 중 하나: (a) last analyzed 시각 vs HEAD commit 시각 → HEAD가 더 최신, (b) last analyzed가 24h 이상 경과, (c) `group_status`에 stale 그룹 존재 |
| **fresh** | 위 어느 것도 아님 |

### 1-c. 상태별 동작

- **fresh** → Phase 2로 바로 진행.
- **stale / not-indexed** → 사용자에게 **반드시 확인 받고** 실행:

  ```
  인덱스 상태: <stale | 미인덱싱>
    - last analyzed: <timestamp or N/A>
    - HEAD: <short sha> (<relative time>)
    - 예상 소요: <repo 크기 기반 가늠; 모르면 "알 수 없음">

  지금 `gitnexus analyze` 재실행할까요? (y/N)
  ```

  - **y** → `Bash`로 `cd <repo> && gitnexus analyze` 실행 → 종료 후 `list_repos`로 재확인 → Phase 2.
  - **N / 무응답** → 현재 stale 인덱스로 진행하되, **답변 서두에 `⚠️ stale index` 경고** 고정.

### 1-d. 예외

- `gitnexus` CLI 없음 / MCP 미등록 → 설치 안내 후 종료:
  ```
  GitNexus 미설치. 루트에서:
    npm install -g gitnexus
    claude mcp add gitnexus -- npx -y gitnexus@latest mcp
    cd <repo> && gitnexus analyze
  ```
- `analyze` 실행 실패 → 에러 그대로 보고하고 stale 인덱스로 fallback 여부 사용자에게 재확인.

---

## Phase 2: 분류

질문을 **의도(intent)** 로 분류. 여러 개 동시 해당 가능.

| Intent | 트리거 키워드 | 사용할 GitNexus 도구 |
|---|---|---|
| symbol-lookup | "X가 뭐 해?", "signature", "where defined" | `context`, `shape_check` |
| impact | "바꾸면 뭐 깨져?", "누가 써?", "지워도 되나?" | `impact`, `api_impact` |
| flow-trace | "어떻게 흘러가?", "call path", "sequence" | `route_map`, `context`, `cypher` |
| semantic | "X하는 코드 찾아줘", "Y 처리 부분" | `query`, `group_query` |
| structure | "모듈 구조", "cluster 개요", "어떤 서비스들" | `group_list`, `group_contracts`, `cypher` |
| change-impact | "이 diff 영향 범위", "commit 스코프" | `detect_changes`, `impact` |
| api-surface | "endpoint 목록", "HTTP routes" | `route_map`, `tool_map` |
| rename-safety | "X 이름 바꿔도 돼?", "usages" | `rename` (dry-run), `context` |

**복잡도 판단:**
- 단일 intent + 단일 심볼 → **직접 실행** (Phase 3a)
- 2개 이상 intent OR 여러 심볼의 영향 교차분석 OR 의미 검색 필요 → **에이전트 위임** (Phase 3b)

---

## Phase 3: 실행

### 3a — 직접 실행 (단순 질의)

해당 intent의 GitNexus 도구 1-2개를 병렬 호출. 결과가 명확하면 그대로 Phase 4로.

예:
- "train()이 뭐 해?" → `context(symbol="train")` 한 번
- "/v1/predict 핸들러?" → `route_map(path="/v1/predict")` 한 번

### 3b — 에이전트 위임 (복합 질의)

`codebase-researcher` 에이전트에게 위임. 프롬프트 템플릿:

```
QUESTION: {원문 질문}
REPO: {list_repos 결과에서 고른 slug, 없으면 생략}
FOCUS: {있으면 지정}

답변 형식은 codebase-researcher 에이전트 규칙에 따름.
읽기 전용. 편집 금지.
```

에이전트는 `context`/`impact`/`query` 등을 병렬 호출하고 합성된 리포트를 반환.

---

## Phase 4: 답변

모든 인용은 `file:line` 형태로. GitNexus 결과가 존재하지 않는 파일을 가리키면 `Read`/`Glob`로 검증 후 `(stale index)` 표시.

**응답 구조:**

```markdown
## {질문 한 줄 재진술}

**답:** {2-3 문장 직접 답}

**근거:**
- `symbol_name()` — path/to/file.py:142 (role)
- ...

**관련 코드 (semantic):** (있을 때만)
- path/to/other.py:88 — 이유

**주의점:** (있을 때만)
- {간접 호출자, dynamic dispatch, config 기반 분기 등}
```

답이 3줄로 충분하면 3줄로. 템플릿 강요하지 않음.

---

## 부분 실행

| 요청 | 실행 범위 |
|---|---|
| "질문에 답해줘" | Phase 1→4 전체 |
| "intent만 분류해줘" | Phase 1→2 |
| "GitNexus 세팅 확인만" | Phase 1 |
| "더 깊이 파줘" | 강제 에이전트 위임 (Phase 3b) |

---

## 원칙

- **읽기 전용.** 이 스킬은 코드/문서 편집 금지.
- **병렬 우선.** 독립 호출은 한 메시지에서 병렬.
- **증거 없이 단언 금지.** 확인 안 된 심볼/파일은 `(unverified)`.
- **얇게 유지.** 복잡한 종합은 에이전트에 위임하고 스킬은 라우팅만.
- **인덱스 신선도.** Phase 1에서 stale 판정. stale 인덱스로 진행한 경우 답변 서두에 `⚠️ stale index` 고정.

---

## GitNexus 도구

도구별 상세 + intent → 병렬 호출 매핑: `references/gitnexus-tools.md` (SKILL.md와 `codebase-researcher` 에이전트가 공유).
