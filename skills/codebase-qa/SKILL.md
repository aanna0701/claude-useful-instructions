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

## Phase 1: 전처리

1. `mcp__gitnexus__list_repos` 호출 — 현재 repo가 indexed 되어 있는지 확인.
2. 없으면 즉시 안내하고 종료:
   ```
   GitNexus가 이 repo에 없음. 루트에서 다음 실행:
     gitnexus analyze
   ```
   (README의 "GitNexus setup" 섹션 참조)
3. index 존재 → 그룹 컨텍스트 파악을 위해 필요시 `group_status` / `group_list`.

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
- **인덱스 신선도.** `>24h` 오래된 인덱스면 답변 서두에 경고.

---

## GitNexus 도구 치트시트

> 상세: `references/gitnexus-tools.md`

| 도구 | 언제 |
|---|---|
| `list_repos` | 항상 첫 호출, indexed repo 확인 |
| `context(symbol=...)` | 심볼 360도 뷰 (signature, callers, callees, process) |
| `impact(symbol=...)` | blast radius — 바꾸면 영향 받는 심볼/모듈 |
| `api_impact(...)` | HTTP/RPC API 수준 영향 |
| `query(q=...)` | hybrid BM25+semantic 검색 |
| `detect_changes(...)` | git diff → 영향 받는 process/cluster 맵핑 |
| `route_map(...)` | HTTP 라우트 카탈로그 / 특정 경로 flow |
| `tool_map(...)` | MCP/agent tool 카탈로그 |
| `cypher(q=...)` | 원본 Cypher 쿼리 (그래프 패턴 매칭) |
| `shape_check(...)` | 함수 시그니처 검증 |
| `rename(...)` | rename dry-run으로 usages 확인 |
| `group_*` | cluster/process 그룹 연산 |
