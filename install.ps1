$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Candidates = @(
  (Join-Path $env:APPDATA 'Luanti\mods'),
  (Join-Path $env:APPDATA 'Minetest\mods')
)
$Dest = $Candidates | Where-Object { Test-Path (Split-Path $_) } | Select-Object -First 1
if (-not $Dest) { $Dest = $Candidates[0] }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Get-ChildItem (Join-Path $Root 'mods') -Directory -Filter 'edu_*' | ForEach-Object {
  # Replace the installed copy instead of merging into it. A plain copy leaves
  # files that a later version renamed or dropped, and a stale file shadows the
  # current one when Luanti loads the mod.
  $Target = Join-Path $Dest $_.Name
  if (Test-Path $Target) { Remove-Item $Target -Recurse -Force }
  Copy-Item $_.FullName $Dest -Recurse -Force
}
Write-Host "Installed Studium mods in $Dest"
