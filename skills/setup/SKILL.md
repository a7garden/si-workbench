---
name: setup
description: Use when setting up or troubleshooting si-workbench — "si-workbench 설정", "setup", "초기 설정", "vault 경로 바꿔줘", "환경 진단", "플러그인 동작 확인" — or right after install, before init-vault.
---

# setup — 설정 및 환경 진단

설정 값을 확인·수집하고 실행 환경을 점검한다. 재실행 멱등: 이미 설정된 항목은 다시 묻지 않고 통과 표시한다.

## 안전 규칙

- 진단은 읽기 전용 확인(`--version`, 파일 존재 확인)만 한다. 도구 설치를 임의로 진행하지 않는다 — 방법만 안내한다.
- 원격 저장소 변경(`git push`, `svn commit`) 금지. 이 스킬이 네트워크로 무언가를 전송하는 일도 없다.
- 파일 쓰기는 2곳뿐이다: `%USERPROFILE%\.claude\si-workbench\config.json`, 그리고 사용자가 동의한 경우뿐.

## 1. vault 경로

1. `${user_config.vault_path}` 값을 이 본문에서 읽는다. 값이 있고 그 디렉토리가 실존하면 ✓ 통과.
2. 비어있거나 실존하지 않으면 `%USERPROFILE%\.claude\si-workbench\config.json`의 `vaultPath`를 확인한다. 값이 있고 실존하면 ✓. (이 파일은 userConfig 다음 우선순위다.)
3. 둘 다 없으면 사용자에게 Obsidian vault 절대경로를 묻고, 답을 받아 config.json을 작성/갱신한다:

   ```json
   {"vaultPath": "C:\\Users\\me\\Documents\\WorkVault"}
   ```

   - 기존 파일이 있으면 `vaultPath` 키만 갱신한다.
   - 영구 설정의 우선 방법은 `/plugin`에서 si-workbench의 `vault_path` 옵션을 편집하는 것임을 안내한다.

## 2. 환경 진단

아래 표 형식으로 보고한다 (항목 | 상태 ✓/✗ | 조치):

| 항목 | 확인 방법 | ✗일 때 조치 안내 |
|---|---|---|
| vault 디렉토리 | 1단계에서 확인 | 경로 재질문 |
| Obsidian 템플릿 설정 | `<vault>/.obsidian/templates.json` 존재 | `/si-workbench:init-vault` 실행 제안 |
| pandoc | `pandoc --version` | docx 파싱은 Word 자동화로 폴백됨. 설치 권장: https://pandoc.org/installing |
| Node.js (v18+) | `node --version` | Playwright 스크린샷만 제한, 나머지 기능 정상 |
| Playwright MCP | 세션의 `/mcp` 화면에서 playwright 상태 확인 | 미연결이면 README '자주 묻는 질문'의 Windows npx 우회법 안내 |
| 저널 훅 | `%USERPROFILE%\.claude\si-workbench\journal\` 확인 | 신규 설치면 세션 1회 종료 후 생성됨. 지금 비어 있어도 정상 |

## 3. 마무리

- 진단 표와 수행한 설정 변경을 요약 보고한다.
- vault 구조(`템플릿/`, `일지/`, `사업/`, `개념/`, `첨부/`)가 없으면 `/si-workbench:init-vault` 실행을 제안한다.
