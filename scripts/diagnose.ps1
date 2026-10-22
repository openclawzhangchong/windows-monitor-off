# Read-only check: why a monitor may refuse to stay off, and whether the PC can sleep.
# Run from a PowerShell window:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\diagnose.ps1
$ErrorActionPreference = 'Continue'

try { [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(936) } catch { }

Write-Output '=== [1] supported sleep states ==='
& powercfg /a
Write-Output ''
Write-Output '=== [2] who holds DISPLAY / SYSTEM awake (DISPLAY here blocks auto power-off; needs admin) ==='
& powercfg /requests 2>&1
Write-Output ''
Write-Output '=== [3] system sleep timeouts (index 0x00000000 = Never) ==='
& powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE
Write-Output ''
Write-Output '=== [4] Windows own idle display-off timeouts ==='
& powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE
Write-Output ''
Write-Output '=== [5] screens ==='
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
    '{0}  primary={1}  {2}' -f $_.DeviceName, $_.Primary, $_.Bounds
}
Write-Output ''
Write-Output 'How to read this:'
Write-Output '  [2] DISPLAY  - a program listed there keeps the panel lit; it is the usual reason a manual'
Write-Output '                  turn-off "reverses itself" a second later. Quit it and retry.'
Write-Output '  [3] AC index - if it is not 0x00000000 the PC really sleeps after that many seconds, which'
Write-Output '                  kills background work. Turning the display off does not touch this.'
