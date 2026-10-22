param(
    [string]$Version = '1.0.0',
    [string]$BinDir
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $BinDir) { $BinDir = Join-Path $root 'bin' }

$cscCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$csc = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) {
    throw 'csc.exe not found. Need the .NET Framework 4.x C# compiler (ships with Windows 10/11).'
}
Write-Output "compiler : $csc"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$exe = Join-Path $BinDir 'ScreenOff.exe'
$src = Join-Path $root 'src\ScreenOff.cs'

# The in-box compiler is the legacy one (4.8.9221.0, "for C# 5"): it has no /version
# switch, so assembly metadata comes from a generated attribute file.
$asm = Join-Path $BinDir 'AssemblyInfo.cs'
@(
    'using System.Reflection;'
    ''
    '[assembly: AssemblyTitle("ScreenOff")]'
    '[assembly: AssemblyDescription("Turn the monitors off while the PC keeps working")]'
    '[assembly: AssemblyProduct("ScreenOff")]'
    '[assembly: AssemblyCompany("openclawzhangchong")]'
    '[assembly: AssemblyCopyright("Copyright (c) 2026 openclawzhangchong")]'
    ('[assembly: AssemblyVersion("{0}.0")]' -f $Version)
    ('[assembly: AssemblyFileVersion("{0}.0")]' -f $Version)
) | Set-Content -LiteralPath $asm -Encoding ASCII

if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }

& $csc '/nologo' '/target:winexe' '/optimize+' '/platform:anycpu' `
    '/r:System.Windows.Forms.dll' '/r:System.Drawing.dll' `
    "/out:$exe" $src $asm
if ($LASTEXITCODE -ne 0) { throw "csc failed, exit code $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $exe)) { throw "csc reported success but $exe is missing" }

# Release asset pair: the bare exe plus a zip carrying the docs with it.
$stage = Join-Path $BinDir 'stage'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item -LiteralPath $exe -Destination $stage
foreach ($doc in @('README.md', 'LICENSE', 'CHANGELOG.md')) {
    $path = Join-Path $root $doc
    if (-not (Test-Path -LiteralPath $path)) { throw "missing $doc - repository tree is incomplete" }
    Copy-Item -LiteralPath $path -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $root 'docs\LESSONS.md') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'scripts\diagnose.ps1') -Destination $stage

$zip = Join-Path $BinDir "ScreenOff-v$Version-win-x64.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -LiteralPath $stage -Recurse -Force

$lines = @()
foreach ($asset in @($exe, $zip)) {
    $item = Get-Item -LiteralPath $asset
    $hash = (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLower()
    $lines += ('{0}  {1}  {2} bytes' -f $hash, $item.Name, $item.Length)
}
$lines | Set-Content -LiteralPath (Join-Path $BinDir 'sha256.txt') -Encoding ASCII
$lines | ForEach-Object { Write-Output $_ }
