' Double-click this (or the "Guan Xian Shi Qi" desktop shortcut) to blank the
' monitors. The PC keeps running. Any mouse move or key press wakes the panel.
' Window style 0 = no console flash.
Option Explicit

Dim sh, dir, ps, powershell, cmdline
Set sh = CreateObject("WScript.Shell")

dir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
ps = dir & "monitor-off.ps1"
powershell = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"

cmdline = """" & powershell & """ -NoProfile -ExecutionPolicy Bypass -File """ & ps & """ -DelaySec 2"

If WScript.Arguments.Count > 0 Then
    cmdline = """" & powershell & """ -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File """ & ps & """ " & WScript.Arguments(0)
    sh.Run cmdline, 1, True
Else
    sh.Run cmdline, 0, False
End If
