# Stage 2: Career Description & Essay

Stage 1 컨텍스트 기반으로 AI가 직접 작성. **Stage 2에서는 NLM 추가 쿼리 없음** (Stage 1에서 이미 충분히 추출/분석).

## 2.1 상세 경력 기술서

연도순 (oldest → newest). Stage 1 컨텍스트 정리 문서를 기반으로 작성.

**항목 형식:**
```markdown
### [회사명] — [직책] (YYYY.MM ~ YYYY.MM)
[역할 범위 2-3문장]
**주요 프로젝트 및 성과:**
- [프로젝트명]: [구체적 기여] → [수치 성과]
**핵심 역량:** [키워드]
```

**톤 규칙:** 사실적, 수치 기반, 본인 기여 특정, 과장 금지.

## 2.2 인사 관점 에세이

에세이 형태 (800-1500자). Stage 1에서 추출한 협업/리더십 사례 기반으로 작성.

**다룰 주제:** 협업, 리더십/멘토링, 커뮤니케이션, 문제해결 접근법, 조직 기여
**규칙:** 모든 주장에 구체적 사례 근거, 빈 성격 묘사 금지 ("성실합니다" X), show don't tell

## 2.3 Upload & Session Split

업로드:
```
nlm source add "자소서" --text "..." --title "경력_기술서_YYYYMMDD_HHMM"
nlm source add "자소서" --text "..." --title "인사관점_에세이_YYYYMMDD_HHMM"
```

**세션 분리 메시지 출력** (cover-letter.md "Session Split" 섹션 참조).
