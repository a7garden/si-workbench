# si-workbench SessionEnd hook: append one JSONL line to the daily work journal.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$e = $raw | ConvertFrom-Json
if (-not $e.session_id) { exit 0 }
$dir = Join-Path $env:USERPROFILE '.claude\si-workbench\journal'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$rec = [ordered]@{
  ts              = (Get-Date).ToString('o')
  session_id      = $e.session_id
  cwd             = $e.cwd
  transcript_path = $e.transcript_path
  reason          = $e.reason
}
$line = $rec | ConvertTo-Json -Compress
$name = (Get-Date).ToString('yyyy-MM-dd') + '.jsonl'
$path = Join-Path $dir $name
for ($attempt = 0; $attempt -lt 5; $attempt++) {
  try {
    $ErrorActionPreference = 'Stop'
    [System.IO.File]::AppendAllText($path, $line + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    break
  } catch {
    $ErrorActionPreference = 'SilentlyContinue'
    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 60)
  }
}
exit 0
