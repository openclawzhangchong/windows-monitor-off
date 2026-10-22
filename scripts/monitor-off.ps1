param(
    [int]$DelaySec = 2,
    [ValidateSet('Broadcast', 'Post', 'Both')]
    [string]$Method = 'Both',
    [switch]$Diagnose,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'
if (-not $LogFile) { $LogFile = Join-Path $PSScriptRoot 'monitor-off.log' }

function Write-Log {
    param([string]$Message)
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogFile -Value $line
}

$native = @'
using System;
using System.Runtime.InteropServices;

public static class MonOff
{
    private const uint WM_SYSCOMMAND = 0x0112;
    private const int SC_MONITORPOWER = 0xF170;
    private const int MONITOR_STATE_OFF = 2;
    private const uint SMTO_ABORTIFHUNG = 0x0002;
    private const uint ES_CONTINUOUS = 0x80000000;
    private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam,
        uint flags, uint timeout, out IntPtr result);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint SetThreadExecutionState(uint esFlags);

    public static void ClearDisplayRequests()
    {
        SetThreadExecutionState(ES_CONTINUOUS);
    }

    public static void SendOff()
    {
        IntPtr dummy;
        SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, (IntPtr)SC_MONITORPOWER,
            (IntPtr)MONITOR_STATE_OFF, SMTO_ABORTIFHUNG, 2000, out dummy);
    }

    public static void PostOff()
    {
        PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, (IntPtr)SC_MONITORPOWER,
            (IntPtr)MONITOR_STATE_OFF);
    }
}
'@

Add-Type -TypeDefinition $native

if ($Diagnose) {
    try { [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(936) } catch { }
    Write-Output '=== [1] supported sleep states ==='
    & powercfg /a
    Write-Output ''
    Write-Output '=== [2] what holds DISPLAY / SYSTEM awake (needs admin) ==='
    & powercfg /requests 2>&1
    Write-Output ''
    Write-Output '=== [3] system sleep timeout ==='
    & powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE
    Write-Output ''
    Write-Output '=== [4] windows own display-off idle timeout ==='
    & powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE
    Write-Output ''
    Write-Output '=== [5] screens ==='
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
        '{0}  primary={1}  {2}' -f $_.DeviceName, $_.Primary, $_.Bounds
    }
    exit 0
}

Write-Log "run: DelaySec=$DelaySec Method=$Method"
Write-Log "countdown started"
if ($DelaySec -gt 0) { Start-Sleep -Seconds $DelaySec }

# Some apps (players, meeting tools, drivers) register a display-required
# request that instantly re-lights the panel. Drop ours before broadcasting.
[MonOff]::ClearDisplayRequests()

switch ($Method) {
    'Broadcast' { [MonOff]::SendOff() }
    'Post' { [MonOff]::PostOff() }
    'Both' {
        [MonOff]::SendOff()
        Start-Sleep -Milliseconds 250
        [MonOff]::PostOff()
    }
}

Write-Log "off request sent ($Method)"
