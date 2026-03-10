# claude-useful-instructions

나만의 Claude Code 설정 모음. 어느 머신에서든 `./install.sh` 한 번으로 적용됩니다.

## 구조

```
claude-useful-instructions/
├── commands/
│   └── sync-docs.md    # /sync-docs 커맨드
└── install.sh          # ~/.claude/ 에 설정 복사
```

## 설치

```bash
git clone https://github.com/aanna0701/claude-useful-instructions.git
cd claude-useful-instructions
./install.sh
```

## Commands

### `/sync-docs`

프로젝트 문서를 현재 코드베이스 상태에 맞게 자동 갱신합니다.

- `.md`, `.toml`, `requirements.txt`, `package.json`, `Cargo.toml` 등 모든 명세/의존성 파일 스캔
- `git diff` 분석으로 최근 변경사항 반영
- 문서와 실제 코드 간 불일치 감지 후 업데이트

```
/sync-docs           # 변경된 모든 .md 파일 갱신
/sync-docs README.md # 특정 파일만 갱신
```

## 새 설정 추가

1. `commands/` 에 `.md` 파일 추가
2. `git commit && git push`
3. 다른 머신에서 `git pull && ./install.sh`
