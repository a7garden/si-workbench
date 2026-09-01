# si-workbench 설계 문서

SI 업무용 Claude Code 플러그인. Obsidian vault를 개인 지식베이스(위키)로 쓰고,
업무일지·업무 보고·제안서/코드베이스 분석 문서화를 자동화한다.

## 대상 환경

- Windows 10/11 업무용 PC, Claude Code CLI (v2.1.x 이상 권장)
- PowerShell 5.1+ (Windows 기본) — 훅 스크립트 실행
- 권장: Node.js 18+ (Playwright MCP 스크린샷), pandoc (docx 파싱)
- macOS/Linux에서도 동작하도록 스킬은 경로 변수를 쓰되, 1차 타깃은 Windows

## 저장소 구조 (repo = 마켓플레이스 + 플러그인)

```
si-workbench/
  .claude-plugin/plugin.json        # name, version, userConfig(vault_path)
  .claude-plugin/marketplace.json   # 단일 플러그인, source: "./"
  skills/                           # 6개 스킬 (아래)
  hooks/hooks.json                  # SessionEnd, PreToolUse
  hooks/scripts/journal-append.ps1
  hooks/scripts/block-push.ps1
  templates/                        # vault용 노트 템플릿 5종
  .mcp.json                         # Playwright MCP
  README.md, LICENSE(MIT), docs/design.md
```

## Vault 구조

```
<VAULT>/                            # ${user_config.vault_path}
  템플릿/                           # Obsidian core Templates 플러그인 폴더
  일지/YYYY-MM-DD.md
  사업/<사업명>/
    <사업명>.md                     # 사업 허브(MOC)
    분석/                           # codebase-docs 산출물 (기능 1개 = 문서 1개)
    산출물/
    회의/
  개념/<개념명>.md                  # 위키 노트
  첨부/스크린샷/<사업명>/
```

- 사업/연구 구분은 폴더가 아니라 `type` 프로퍼티. 둘 다 `사업/` 아래에 둔다.

## 프로퍼티 스키마 (영어 키 + 한국어 값)

| 노트 | frontmatter |
|---|---|
| 사업 허브 | `type: 사업\|연구`, `status: 예비\|진행중\|완수\|보류`, `client`, `period`, `parent`, `related[]`, `codebase`, `vcs: git\|svn`, `tags[]` |
| 개념 | `type: 개념`, `aliases[]`, `related[]`, `sources[]`, `tags[]` |
| 일지 | `type: 일지`, `tags[]` |
| 기능분석 | `type: 기능분석`, `sources[]`, `related[]`, `status: 초안\|검토완료`, `tags[]` |
| 회의 | `type: 회의`, `date`, `participants[]`, `project`, `related[]`, `tags[]` |

규칙: 스킬이 임의 필드를 만들지 않는다. 모르는 값은 비워둔다. 값은 한국어.

## 위키 규범 (모든 스킬이 준수 — `si-workbench:wiki` 스킬이 규범 본문)

1. 문서에 개념 첫 등장 시 `[[개념명]]` 위키링크. 노트가 없으면 템플릿으로 생성 후 링크 (죽은 링크 금지).
2. 개념 노트: 2-3문장 정의 + `sources` 출처 + `related`. 다른 노트와 본문 중복 금지 — 링크로 연결.
3. 기능분석 문서: 실제 파일 경로는 frontmatter `sources`에만 적는다. 본문은 추상 서술 + mermaid 다이어그램. 경로 변경에 본문이 썩지 않는 구조.
4. 사업 허브 = MOC: 분석 문서·주요 개념·산출물 링크 목록을 최신으로 유지.
5. 프로퍼티는 템플릿 스키마만 사용.

## 일지 파이프라인

```
세션 종료 → SessionEnd 훅(자동)
  → %USERPROFILE%\.claude\si-workbench\journal\YYYY-MM-DD.jsonl
    한 줄: {"ts","session_id","cwd","transcript_path","reason"}

/si-workbench:daily-log  → 오늘 저널 → transcript 샘플링 → 상세 업무기록
  → 일지/오늘.md 의 `## 업무기록` 섹션 전체 교체 (재실행 멱등, 노트 없으면 생성)
/si-workbench:daily-report → 동일 분석 → 보고 형식 코드블록 1개 출력
```

- transcript 샘플링: user 발화 + summary 항목 중심. JSONL 통독 금지.
- 같은 session_id가 여러 줄이면 마지막 것만 유효.
- `$ARGUMENTS`로 구두 업무(회의 등) 추가 입력 가능.

## 보고 형식 (daily-report 표준 출력)

- 단일 fenced 코드블록. 날짜·인사·마크다운 장식 금지. 복사→붙여넣기 그대로.
- `[분류]`는 그날 내용을 보고 AI가 추론. 항목은 `- ` 한 줄. 카테고리 사이 빈 줄.

```
[분류1]
- 업무내용1
- 업무내용2

[분류2]
- 업무내용1
```

## 훅

| 훅 | 스크립트 | 동작 |
|---|---|---|
| `SessionEnd` (전체) | journal-append.ps1 | 저널 JSONL 1줄 추가. 실패해도 조용히 exit 0 |
| `PreToolUse` (`Bash\|PowerShell`) | block-push.ps1 | `git push`, `svn commit/ci`, `git svn dcommit`, `hg push` → ask(실행 전 확인 프롬프트 강제) |

- 원칙: 회사 저장소 원격 변경은 완전 차단이 아니라 **항상 확인**. 사용자가 승인하면 실행됨. 로컬 `git commit`은 확인 없이 허용.
- ps1은 UTF-8 **with BOM**으로 저장 (Windows PowerShell 5.1 한글 파싱).
- 훅 스크립트 경로는 `${CLAUDE_PLUGIN_ROOT}` 변수 사용.

## 스킬 (6개, 네임스페이스 `/si-workbench:*`)

| 스킬 | 역할 |
|---|---|
| `wiki` | 개념 노트 규범 본문. 다른 모든 스킬이 이 규범을 준수함을 명시 |
| `init-vault` | vault 스캐폴딩 + 템플릿 복사 + .obsidian/templates.json 설정. 재실행 안전(기존 파일 보존) |
| `daily-log` | 상세 업무기록 → 일지 노트 `## 업무기록` 교체 |
| `daily-report` | 보고 형식 요약 → 코드블록 출력 |
| `project-doc` | 사업 등록: 제안서(docx: pandoc, 없으면 Word COM) + 코드베이스 경로 → 사업 폴더/허브/요약 |
| `codebase-docs` | 코드베이스 → 기능별 기능분석 문서(mermaid 필수) + 필요시 Playwright 스크린샷 → 첨부/스크린샷 |

공통: vault 경로는 `${user_config.vault_path}`로 주입. docx 우선순위 pandoc → Word COM.

## 보안/정책

- 플러그인 어디에도 원격 전송/push 로직 없음. vault는 로컬 파일 그대로(기본 git 초기화 안 함).
- 정부사업 특성상 세션 내용은 vault(로컬)에만 저장. 외부 동기화 가정 없음.
