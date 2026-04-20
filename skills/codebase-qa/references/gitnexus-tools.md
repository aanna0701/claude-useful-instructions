# GitNexus MCP Tools — Reference

코드베이스 질의응답에 쓰는 GitNexus MCP 도구 레퍼런스. `codebase-qa` 스킬과 `codebase-researcher` 에이전트가 공유한다.

## 기본 가정

- GitNexus는 코드를 **그래프**로 인덱싱한다: 심볼(함수/클래스/메서드) = 노드, 호출/상속/import = 엣지, 추가로 cluster/process/group 상위 개념.
- 모든 질의는 indexed repo에 대해서만 동작. `list_repos`로 먼저 확인.
- 인덱스는 시간 경과에 따라 stale 될 수 있다 — 중요한 결정 전에 `group_status` 또는 파일 직접 확인.

---

## 도구별 가이드

### `list_repos`
현재 환경에서 indexed 된 repo 목록.
- **첫 호출**: 거의 항상 이걸로 시작.
- **출력**: repo slug + last analyzed timestamp.
- **의사결정**: 없으면 `gitnexus analyze` 실행 안내 후 종료.

### `context(symbol=..., repo=...)`
심볼 하나의 360도 뷰.
- 리턴: signature, parameters, return type, docstring, callers, callees, 속한 process, 속한 cluster.
- **언제**: "이 함수가 뭐 해?", "누가 부름?", "뭘 부름?".
- **팁**: 모호한 이름은 `query`로 먼저 좁히고 정확한 심볼 이름으로 `context` 호출.

### `impact(symbol=..., repo=...)`
심볼 변경 시 영향 받는 노드들 — 직접 + 전이 의존.
- **언제**: "이거 바꿔도 돼?", "지워도 안전?", "리팩토링 범위?".
- **출력 해석**: transitive 호출자가 수십 개 나오면 직접 호출자부터 답변에 포함, 전이 호출자는 요약.

### `api_impact(route=..., repo=...)`
HTTP/RPC 엔드포인트 수준 영향 분석.
- **언제**: "/v1/predict 바꾸면 어디까지 영향?".
- `impact`보다 API 경계 기준으로 집계됨.

### `query(q=..., repo=..., limit=...)`
Hybrid BM25 + semantic 검색.
- **언제**: 심볼 이름을 모를 때. "인증 토큰 다루는 코드", "loss 계산하는 부분".
- **출력**: ranked hits (symbol + file + score).
- **팁**: 쿼리는 자연어 OR 도메인 용어. 상위 3-5개만 deep-dive.

### `detect_changes(diff=... or commit_range=..., repo=...)`
git diff → 영향 받는 process/cluster 맵핑.
- **언제**: "이 PR 스코프가 뭐야?", "이 커밋들 합친 영향은?".
- `git diff {range}` 와 결합해서 쓰는 게 가장 정확.

### `route_map(path=..., method=..., repo=...)`
HTTP 라우트 카탈로그.
- **인자 없이 호출**: 전체 엔드포인트 목록.
- **path 지정**: 해당 경로의 핸들러 + 호출 체인.
- **언제**: "엔드포인트 전체 리스트", "이 URL 처리 흐름".

### `tool_map(repo=...)`
Agent/MCP tool 카탈로그. 보통 agent repo에서만 유용.
- **언제**: agent 프로젝트에서 "어떤 tool이 있어?" 질문.

### `cypher(q=..., repo=...)`
Neo4j Cypher 쿼리 원본 실행.
- **언제**: 표준 도구로 표현 안 되는 그래프 패턴 — 예: "A → B → C 3-hop 경로", "in-degree 10 이상 함수".
- **주의**: 쿼리 작성 난이도 있음. 단순 질의는 `context`/`impact` 조합으로 충분.
- 쿼리 예:
  ```cypher
  MATCH (a:Symbol {name:'train'})-[:CALLS*1..3]->(b:Symbol)
  RETURN b.name, b.file, b.line
  ```

### `shape_check(symbol=..., expected=..., repo=...)`
심볼 시그니처가 기대값과 일치하는지 검증.
- **언제**: 문서/스펙의 signature가 실제 코드와 일치하는지 확인. 주로 `sync-docs` 계열이 사용.

### `rename(symbol=..., new_name=..., repo=..., dry_run=true)`
리네임 dry-run — 모든 usages 열람.
- **언제**: "X 이름 바꾸면 몇 군데 수정?".
- **주의**: dry-run으로만 사용. 실제 편집은 이 스킬 범위 밖.

### `group_list` / `group_query` / `group_status` / `group_contracts` / `group_sync`
cluster / process / bounded context 수준 그룹 연산.
- `group_list`: 전체 그룹 목록.
- `group_query(group=..., q=...)`: 특정 그룹 내 검색.
- `group_status`: 그룹 인덱스 상태 (stale 여부 포함).
- `group_contracts`: 그룹 경계 계약.
- **언제**: 아키텍처 레벨 질문 ("data-pipeline cluster에 뭐 있어?").

---

## Intent → 도구 조합 빠른 참조

| Intent | 병렬 호출 |
|---|---|
| symbol-lookup | `context` (+ `shape_check` if 문서 검증) |
| impact | `context` + `impact` (병렬) |
| flow-trace (API) | `route_map(path=...)` → 결과에서 handler 추출 → `context` (병렬로 각 callee) |
| flow-trace (일반) | `context(A)` + `context(B)` (병렬) → `cypher` 경로 쿼리 |
| semantic-search | `query` → top 3-5에 `context` (병렬) |
| structure | `group_list` + `group_contracts` |
| change-impact | `git diff {range}` → `detect_changes` → 각 심볼 `impact` (병렬) |
| api-surface | `route_map` (args 없이) 또는 `tool_map` |
| rename-safety | `rename(dry_run=true)` + `context` |

---

## 결과 검증 체크

1. GitNexus가 반환한 `file`이 실제 존재하는지 `Glob`/`Read`로 확인 (stale index 대비).
2. `context`의 callers가 비어 있으면 `query(q=symbol_name)`로 이중 확인.
3. `impact` 결과가 기대보다 작으면 dynamic dispatch / reflection / config-driven 호출 가능성 — 답변에 gotcha로 명시.
4. `cypher` 결과는 해석 주의. 노드 라벨과 관계 타입이 스키마와 일치하는지 확인.
