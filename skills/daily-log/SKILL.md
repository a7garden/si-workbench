---
name: daily-log
description: Use when the user asks to write or update today's work journal from the day's session records — "업무일지 써줘", "오늘 업무 정리", "업무기록 업데이트", "일지 써줘" 같은 요청을 할 때, 퇴근 전 일지를 정리할 때 사용.
---

# daily-log — 업무일지 작성

오늘의 세션 저널을 분석해 일지 노트의 `## 업무기록` 섹션을 작성한다. 호출: `/si-workbench:daily-log [$ARGUMENTS]`. `$ARGUMENTS`에는 세션에 남지 않은 구두 업무(회의 등)를 적는다.

## 공통 원칙

- 코드베이스는 읽기 전용으로만 다룬다. 어떤 저장소의 파일도 수정/삭제하지 않는다.
- 원격 저장소 변경 주의: `git push`, `svn commit`/`svn ci`, `git svn dcommit`, `hg push`는 불필요하면 실행하지 않는다. 로컬 `git commit`은 자유이며, 훅(block-push.ps1)이 원격 변경은 실행 전 사용자 확인을 요구한다.
- 위키 규범은 si-workbench:wiki를 준수한다. 일지 본문에서 개념이 처음 등장하면 `[[개념명]]`으로 링크하고, 개념 노트가 없으면 템플릿(`템플릿/개념.md`) 내용으로 생성한다. 죽은 링크 금지.
- 프로퍼티 키는 영어, 값은 한국어. 스키마는 design.md 표 그대로이며 스킬이 임의 필드를 만들지 않는다.
- vault 경로 결정: `${user_config.vault_path}` → `%USERPROFILE%\.claude\si-workbench\config.json`의 `vaultPath` → 사용자에게 절대경로 문의. 순서대로 시도한다.

## 분석 절차 (daily-report와 공통)

1. **저널 로드** — `%USERPROFILE%\.claude\si-workbench\journal\<오늘>.jsonl`을 읽는다. `<오늘>`은 로컬 날짜 `YYYY-MM-DD`. 라인 스키마: `{"ts","session_id","cwd","transcript_path","reason"}`.
2. **session_id dedup** — 같은 session_id가 여러 줄이면 마지막 것만 유효로 삼는다.
3. **transcript 샘플링** — 유효 라인의 `transcript_path`마다 다음 규칙을 그대로 적용한다:

[SAMPLING] transcript JSONL 샘플링 규칙: (1) 전체 통독 금지. (2) 먼저 라인 수 파악. (3) `"type":"summary"` 라인과 user 발화(`message.role == "user"`이고 content가 문자열이거나 content[].type=="text")를 추출. (4) 마지막 assistant 텍스트 1-2개만 추가. (5) tool_result 본문은 읽지 않는다. 파일이 크면 앞부분 user 발화와 뒷부분 마무리를 우선.

4. **프로젝트별 재구성** — `cwd`를 기준으로 작업을 프로젝트별로 묶고, `ts` 순서(시간순)로 작업 항목을 재구성한다.
5. **$ARGUMENTS 반영** — `$ARGUMENTS`(구두 업무: 회의 등)가 있으면 분석 결과에 추가 업무로 반영한다.
6. **세션이 없는 날** — 저널 파일이 없거나 유효한 세션이 없으면 빈 결과를 보고하고, `$ARGUMENTS`만으로 작성을 진행한다. `$ARGUMENTS`도 없으면 기록할 근거가 없음을 사용자에게 안내하고 종료한다.

## 일지 노트 작성

[SECTION] 일지 노트 = `${user_config.vault_path}/일지/YYYY-MM-DD.md`. `## 업무기록` 헤딩 아래부터 다음 `## ` 헤딩 또는 EOF 직전까지가 교체 범위(헤딩 자체는 유지). 노트가 없으면 템플릿(`템플릿/일지.md`) 내용으로 생성. `## 업무기록` 헤딩이 없으면 문서 끝에 추가. 재실행 시 기존 자동 생성 내용이 통째로 갱신(멱등) — 이 섹션은 자동 생성 전용임을 사용자에게 안내.

기록 작성 규칙:

- 시간순 프로젝트/작업 블록으로 구성한다. 블록과 항목의 순서는 실제 작업 시간 순서를 따른다.
- 각 항목에는 무엇을 했는지, 왜 했는지, 결과(남은 것이 있으면 그것까지)를 담는다.
- 한국어 완결 문장으로 쓴다. 명사 나열·조사 생략 금지.
- 개념 첫 등장 시 `[[개념명]]` 위키링크(노트 없으면 템플릿으로 생성 — 죽은 링크 금지).
- 노트 생성 시 템플릿의 frontmatter(`type: 일지`, `tags`)를 그대로 유지하고 임의 필드를 추가하지 않는다.
- `## 업무기록` 외의 섹션(예: `## 비고`)은 절대 건드리지 않는다.

## 완료 후 보고

작성이 끝나면 무엇을 교체했는지 요약 보고한다:

- 노트를 신규 생성했는지, 기존 `## 업무기록` 섹션을 교체했는지
- 교체한 범위와 주요 변경 내용
- 반영한 세션 수와 프로젝트(cwd) 수, `$ARGUMENTS` 반영 내역
