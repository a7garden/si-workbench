---
name: init-vault
description: Use when the user wants to prepare the Obsidian vault for si-workbench — "vault 초기화해줘", "처음 세팅해줘", "vault 새로 만들어줘", "si-workbench 초기 설정해줘", "템플릿 세팅해줘" — or when another si-workbench skill cannot proceed because the vault folders or 템플릿 templates are missing.
---

# vault 초기화

si-workbench가 쓸 Obsidian vault의 폴더 구조를 만들고 노트 템플릿을 복사한다.
재실행 멱등: 기존 파일과 설정은 절대 덮어쓰지 않으므로 여러 번 실행해도 안전하며, 항상 같은 상태로 수렴한다.

## 공통 정책

- 코드베이스는 읽기 전용으로만 다룬다. 어떤 파일도 수정/삭제하지 않는다.
- 원격 변경 금지: `git push`, `svn commit/ci`, `git svn dcommit`, `hg push`는 실행하지 않는다.
- 이 스킬은 노트를 작성하지 않는다. 이후 모든 노트 작성은 si-workbench:wiki 규범을 준수한다.
- vault는 로컬 전용이다. `git init`이나 클라우드 동기화 설정을 하지 않는다.

## 절차

1. vault 경로 확인
   - `${user_config.vault_path}` 값을 읽는다.
   - 값이 비어있거나 실존하지 않으면 `%USERPROFILE%\.claude\si-workbench\config.json`의 `vaultPath`를 확인한다. 있으면 그 경로를 쓴다.
   - 둘 다 없으면 임의로 추정하지 말고 사용자에게 vault 절대경로를 문의한다. 답을 받으면 그 경로로 진행하고, 사용자 동의를 얻어 config.json에 저장한다(다음 실행부터 자동 적용). 이하 절차의 `${user_config.vault_path}`는 여기서 확정한 경로로 읽는다.
2. 폴더 생성 (이미 있으면 건너뛰고 목록에 기록)
   - `${user_config.vault_path}/템플릿/`
   - `${user_config.vault_path}/일지/`
   - `${user_config.vault_path}/사업/`
   - `${user_config.vault_path}/개념/`
   - `${user_config.vault_path}/첨부/스크린샷/`
   - 사업별 스크린샷 폴더(`첨부/스크린샷/<사업명>/`)는 project-doc, codebase-docs가 필요 시 만든다.
3. 템플릿 복사: `${CLAUDE_PLUGIN_ROOT}/templates/*.md` → `${user_config.vault_path}/템플릿/`
   - 대상 폴더에 같은 이름의 파일이 있으면 덮어쓰지 않고 skip 목록에 기록한다.
   - 복사한 파일과 스킵한 파일을 각각 목록으로 남긴다.
4. Obsidian 템플릿 설정: `${user_config.vault_path}/.obsidian/templates.json`
   - 파일이 없으면 `.obsidian/` 폴더와 함께 아래 내용으로 작성한다.
     ```json
     {"folder":"템플릿"}
     ```
   - 파일이 있으면 `folder` 값을 확인한다. `"템플릿"`이면 그대로 통과하고, 다른 값이면 기존 파일을 덮어쓰지 말고 "현재 템플릿 폴더 설정은 X입니다"라고 안내만 한다.
5. 결과 요약 보고
   - 생성한 폴더 목록, 복사한 템플릿 목록, 스킵한 파일 목록, templates.json 처리 결과를 보고한다.
   - 마무리 안내: Obsidian에서 설정 → 코어 플러그인 → Templates(템플릿) 활성화(이미 활성화면 생략), 템플릿 폴더 위치가 `템플릿`으로 되어 있는지 확인.

## 금지사항

| 금지 | 이유 |
|---|---|
| vault 경로가 비어있을 때 경로 임의 추정/생성 | 잘못된 위치에 vault가 생성됨 — 반드시 사용자에게 절대경로 문의 |
| 기존 템플릿 파일 덮어쓰기 | 사용자가 수정한 템플릿을 보존 — skip 후 목록 보고 |
| 기존 `.obsidian/templates.json` 덮어쓰기 | 기존 Obsidian 설정 존중 — `folder` 값 확인 후 안내만 |
| 템플릿 내용이나 frontmatter 필드 임의 수정 | 프로퍼티 스키마는 design.md 기준으로 고정 |
| vault에 `git init` 또는 원격 동기화 설정 | vault는 로컬 전용 (설계 정책) |
