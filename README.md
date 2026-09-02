# si-workbench

SI 업무를 위한 Claude Code 플러그인. Obsidian vault를 개인 지식베이스(위키)로 사용해
업무일지, 업무 보고, 사업 문서화, 코드베이스 분석을 자동화합니다.

## 기능

- **일과 루틴** — `/si-workbench:morning`(출근 브리핑 + 어제 할 일 자동 이월), `/si-workbench:lunch`(오전 결산), `/si-workbench:evening`(일지 + 보고서 + 내일 할 일 한 번에). 실행만 걸어두고 자리를 비워도 됩니다 — 중간에 질문하지 않고 끝까지 실행한 뒤 보고서를 남깁니다.
- **업무일지** — 세션 종료 때마다 작업 원본이 자동 적립되고, `/si-workbench:daily-log` 한 번으로 오늘 한 일을 일지 노트에 정리합니다.
- **업무 보고** — `/si-workbench:daily-report`가 그날 작업을 보고 형식 코드블록으로 만들어 줍니다. 복사해서 그대로 붙여넣을 수 있습니다.
- **위키** — 문서에 나온 개념을 `[[개념]]` 링크로 연결하고, 없는 개념 노트는 규격 템플릿으로 생성합니다.
- **사업 문서화** — 제안서(docx)와 코드베이스 경로를 주면 사업 허브 문서, 요약, 기능별 분석 문서(mermaid 다이어그램 포함)를 만듭니다.
- **스크린샷 분석** — Playwright MCP로 웹 UI를 헤드리스 캡처해 분석 문서에 첨부합니다.
- **안전장치** — `git push` / `svn commit` 등 원격 저장소 변경은 훅이 감지해 실행 전 항상 확인을 요청합니다.

## 요구사항

| 항목 | 필수 여부 | 비고 |
|---|---|---|
| Windows 10/11 | 권장 | 훅이 PowerShell용. macOS/Linux도 스킬은 동작 |
| Claude Code v2.1.x 이상 | 필수 | |
| Obsidian | 필수 | vault가 이미 있으면 그 경로를 쓰면 됩니다 |
| Node.js 18+ | 선택 | Playwright MCP 스크린샷에 필요. 없으면 스크린샷만 건너뜀 |
| pandoc | 선택 | docx 제안서 파싱에 필요. 없으면 Word 자동화로 폴백 |

## 설치

Claude Code를 열고:

```
/plugin marketplace add a7garden/si-workbench
/plugin install si-workbench@si-workbench
```

설치 중 **Obsidian vault 절대 경로**를 묻습니다 (예: `C:\Users\me\Documents\WorkVault`).
이 경로는 언제든 `/plugin` 설정에서 바꿀 수 있습니다.

안내가 표시되면 `/reload-plugins`로 플러그인을 활성화합니다.

## 첫 실행

```
/si-workbench:setup
/si-workbench:init-vault
```

`setup`이 vault 경로와 실행 환경(Node·pandoc·훅·MCP)을 점검하고 설정합니다. 설정은 `%USERPROFILE%\.claude\si-workbench\config.json`에 저장되며(설치 시 입력한 `/plugin` 설정이 우선), 나중에 언제든 다시 실행해 진단할 수 있습니다.
이미 작성해둔 문서가 있는 vault라면 init-vault 뒤에 `/si-workbench:vault-tidy`를 실행하세요. 기존 문서를 표준 구조로 옮기고, 제목만 있는 빈 노트·부실한 노트·파편화된 노트를 정리합니다 (재구성 전 원본을 git으로 박제해서 언제든 되돌릴 수 있습니다).

vault에 다음 구조를 만들고 노트 템플릿 5종을 복사합니다 (기존 파일은 건드리지 않습니다):

```
<VAULT>/
  템플릿/          # 사업, 개념, 일지, 기능분석, 회의 템플릿
  일지/            # YYYY-MM-DD.md — 업무일지
  사업/<사업명>/   # <사업명>.md 허브 + 분석/ + 산출물/ + 회의/
  개념/            # 위키 노트
  첨부/스크린샷/    # Playwright 캡처
  첨부/다이어그램/  # SVG 분석 다이어그램
```

Obsidian 설정에서 코어 플러그인 **Templates**를 활성화하고 템플릿 폴더를 `템플릿`으로 지정하세요 (init-vault가 `.obsidian/templates.json`을 미리 작성합니다).

## 명령어

### 일과 루틴 (무인 실행 — 걸어두고 비워도 됩니다)

| 명령 | 하는 일 |
|---|---|
| `/si-workbench:morning` | 오늘 일지 노트 준비 + 어제 `내일 할 일` 자동 이월 + 어제 요약 브리핑 |
| `/si-workbench:lunch` | 오전 결산: 오늘 할 일 vs 오전 세션 대조 (읽기 전용) |
| `/si-workbench:evening` | 오늘 할 일 체크 정리 → 일지 `업무기록` 작성 → 보고서 출력 → `내일 할 일` 정리 |

### 도구

| 명령 | 하는 일 |
|---|---|
| `/si-workbench:setup` | 설정·환경 진단 (vault 경로, Node/pandoc, 훅, MCP) |
| `/si-workbench:init-vault` | vault 초기 구조 + 템플릿 세팅 (재실행 안전) |
| `/si-workbench:daily-log` | 오늘 세션 분석 → 일지 노트 `## 업무기록` 섹션 갱신 |
| `/si-workbench:daily-report` | 업무 보고 형식 코드블록 생성 (복붙용) |
| `/si-workbench:project-doc` | 제안서 + 코드베이스로 사업 문서 등록 |
| `/si-workbench:codebase-docs` | 코드베이스 기능별 문서화 (mermaid + 스크린샷) |
| `/si-workbench:wiki` | 개념 노트 생성/정리 (모든 스킬이 따르는 규범) |
| `/si-workbench:vault-tidy` | 기존 문서 표준 구조 재구성·파편 병합·증분 정리 (로컬 git) |

일지·보고는 `$ARGUMENTS`로 회의 등 구두 업무를 덧붙일 수 있습니다:
`/si-workbench:daily-report 오후에 A사 요구사항 미티 1시간`

### 보고 형식 예시

```
[코드 분석]
- 인증 모듈 오류 원인 규명 및 수정
- 배치 누락 건 재처리 로직 점검

[문서 작성]
- A사업 기능분석 문서 2건 작성
```

## 훅

- **SessionEnd** — 세션이 끝날 때마다 `%USERPROFILE%\.claude\si-workbench\journal\YYYY-MM-DD.jsonl`에 기록 한 줄을 추가합니다. 일지/보고 스킬이 이 저널을 읽습니다.
- **PreToolUse** — `git push`, `git send-pack`, `svn commit/ci/import`, `git svn dcommit`, `hg push`를 감지하면 실행 전 확인 프롬프트를 항상 표시합니다. 승인하면 실행되고, 로컬 `git commit`은 확인 없이 실행됩니다.

## 자주 묻는 질문

**Playwright MCP 로드 에러가 나요.** Node.js가 없을 때 나는 메시지로, 나머지 기능에는 영향이 없습니다. 스크린샷이 필요하면 Node.js 18+를 설치하세요. Node가 있는데도 Windows 네이티브에서 로드가 실패하면, 설치된 플러그인의 `.mcp.json`에서 playwright 항목을 `"command": "cmd", "args": ["/c", "npx", "--yes", "@playwright/mcp@0.0.80"]`로 바꾸면 해결되는 경우가 있습니다.

**일지를 하루에 여러 번 돌리면?** `## 업무기록` 섹션만 통째로 갱신됩니다(멱등). 아침에는 `## 오늘 할 일`, 퇴근 전에는 `## 내일 할 일`에 체크박스로 적고, 기타 손 메모는 `## 비고`에 하세요 — 이 섹션들은 자동 갱신 대상이 아닙니다.

**morning이 어제 할 일을 마음대로 옮겨주나요?** 네 — `오늘 할 일`이 템플릿 초기 상태일 때만 자동으로 이월합니다. 미리 뭔가 적어 둔 날은 절대 건드리지 않고 어제 목록을 브리핑에만 표시합니다. 모든 루틴 스킬은 중간에 질문하지 않고, 판단 근거를 마지막 보고에 남깁니다.

**push마다 확인창이 떠요.** 회사 정책 반영입니다 — 원격 저장소 변경은 항상 1회 확인됩니다. 개인 저장소에 자주 push한다면 `/hooks`에서 이 훅만 끄세요.

## 라이선스

MIT
