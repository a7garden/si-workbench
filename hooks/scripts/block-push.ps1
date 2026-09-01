# si-workbench PreToolUse hook: deny remote-mutating VCS commands (company policy).
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$e = $raw | ConvertFrom-Json
$cmd = ''
if ($e.tool_input -and $e.tool_input.command) { $cmd = [string]$e.tool_input.command }
if ($cmd -eq '') { exit 0 }
$deny = $false
if ($cmd -match '(^|[\s;&|(>])git\s+(-[^ ]+\s+)*push\b') { $deny = $true }
if ($cmd -match '(^|[\s;&|(>])svn\s+(-[^ ]+\s+)*(commit|ci)\b') { $deny = $true }
if ($cmd -match 'git\s+svn\s+dcommit') { $deny = $true }
if ($cmd -match '(^|[\s;&|(>])hg\s+push\b') { $deny = $true }
if ($deny) {
  @{
    hookSpecificOutput = @{
      hookEventName          = 'PreToolUse'
      permissionDecision     = 'deny'
      permissionDecisionReason = 'si-workbench 회사 정책: 원격 저장소 변경(git push / svn commit)은 금지되어 있습니다. 로컬 작업만 진행하세요.'
    }
  } | ConvertTo-Json -Depth 5
}
exit 0
