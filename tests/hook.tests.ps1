# si-workbench hook tests. Run: pwsh -NoProfile -File tests/hook.tests.ps1  (or powershell.exe)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$blockPush = Join-Path $repoRoot 'hooks/scripts/block-push.ps1'
$journal = Join-Path $repoRoot 'hooks/scripts/journal-append.ps1'
$exe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell.exe' }

$cases = @(
  @{ cmd = 'git push'; expect = 'ask' },
  @{ cmd = 'git -C repo push origin main'; expect = 'ask' },
  @{ cmd = 'git.exe push'; expect = 'ask' },
  @{ cmd = 'C:\tools\bin\git.exe push origin'; expect = 'ask' },
  @{ cmd = 'git add -A && git push'; expect = 'ask' },
  @{ cmd = 'git svn dcommit'; expect = 'ask' },
  @{ cmd = 'git send-pack host refs/heads/main'; expect = 'ask' },
  @{ cmd = 'svn ci -m x'; expect = 'ask' },
  @{ cmd = 'svn -q commit -m x'; expect = 'ask' },
  @{ cmd = 'svn import . file:///repo'; expect = 'ask' },
  @{ cmd = 'hg push'; expect = 'ask' },
  @{ cmd = 'hg.exe push'; expect = 'ask' },
  @{ cmd = 'git commit -m msg'; expect = 'allow' },
  @{ cmd = 'git pushy --tags'; expect = 'allow' },
  @{ cmd = 'git log push-fix'; expect = 'allow' },
  @{ cmd = 'npm test'; expect = 'allow' }
)

$fail = 0
foreach ($c in $cases) {
  $json = @{ tool_input = @{ command = $c.cmd } } | ConvertTo-Json -Compress
  $out = $json | & $exe -NoProfile -ExecutionPolicy Bypass -File $blockPush
  $decision = 'allow'
  if ($out) { $decision = (($out -join "`n") | ConvertFrom-Json).hookSpecificOutput.permissionDecision }
  if ($decision -ne $c.expect) {
    $fail++
    Write-Host ("FAIL: '{0}' => {1} (want {2})" -f $c.cmd, $decision, $c.expect)
  } else {
    Write-Host ("ok  : '{0}' => {1}" -f $c.cmd, $decision)
  }
}

# journal-append: BOM-less UTF-8, parseable JSONL
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('siwb-test-' + [guid]::NewGuid().ToString('N'))
$oldProfile = $env:USERPROFILE
try {
  $env:USERPROFILE = $tmp
  $in = @{ session_id = 't1'; cwd = 'C:\work'; transcript_path = 't.jsonl'; reason = 'exit' } | ConvertTo-Json -Compress
  $in | & $exe -NoProfile -ExecutionPolicy Bypass -File $journal
  $day = (Get-Date).ToString('yyyy-MM-dd')
  $jpath = Join-Path $tmp ".claude\si-workbench\journal\$day.jsonl"
  if (-not (Test-Path $jpath)) {
    $fail++
    Write-Host 'FAIL: journal file not created'
  } else {
    $bytes = [System.IO.File]::ReadAllBytes($jpath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      $fail++
      Write-Host 'FAIL: journal starts with BOM'
    } else {
      Write-Host 'ok  : journal has no BOM'
    }
    $rec = [System.IO.File]::ReadAllText($jpath) | ConvertFrom-Json
    if ($rec.session_id -ne 't1') {
      $fail++
      Write-Host 'FAIL: journal line not parseable or wrong session_id'
    } else {
      Write-Host 'ok  : journal line parses as JSON'
    }
  }
} finally {
  $env:USERPROFILE = $oldProfile
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}

if ($fail -gt 0) { Write-Host "$fail test(s) failed"; exit 1 }
Write-Host "all $($cases.Count) block-push cases + journal checks passed"
