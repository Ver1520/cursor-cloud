$ErrorActionPreference = "Stop"
# Add Open-with-Cursor to folder BACKGROUND context menu.
# Admin PowerShell:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\add-cursor-folder-context-menu.ps1

param(
    [string]$CursorPath = "",
    [switch]$SkipExplorerRestart
)

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-CursorExecutable {
    param([string]$CustomPath)
    if ($CustomPath) {
        if (Test-Path -LiteralPath $CustomPath) {
            return (Resolve-Path -LiteralPath $CustomPath).Path
        }
        return $null
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Cursor\Cursor.exe"),
        (Join-Path $env:ProgramFiles "Cursor\Cursor.exe")
    )
    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "Cursor\Cursor.exe")
    }
    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    $cmd = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
        return (Resolve-Path -LiteralPath $cmd.Source).Path
    }
    return $null
}

function Get-MenuLabel {
    return ([string][char]0x7528 + " Cursor " + [string][char]0x6253 + [string][char]0x5F00)
}

function Install-BackgroundMenu {
    param(
        [string]$RootPrefix,
        [string]$CursorExe,
        [string]$MenuLabel,
        [string]$ShellKey
    )
    $keyPath = $RootPrefix + "\Directory\Background\shell\" + $ShellKey
    $commandPath = Join-Path $keyPath "command"
    $commandValue = '"' + $CursorExe + '" "%V"'

    New-Item -Path $keyPath -Force | Out-Null
    Set-ItemProperty -LiteralPath $keyPath -Name "(default)" -Value $MenuLabel
    Set-ItemProperty -LiteralPath $keyPath -Name "Icon" -Value ($CursorExe + ",0")
    New-Item -Path $commandPath -Force | Out-Null
    Set-ItemProperty -LiteralPath $commandPath -Name "(default)" -Value $commandValue
}

function Remove-LegacyMenuEntries {
    param([string]$ShellKey)
    $legacyPaths = @(
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\$ShellKey",
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\$ShellKey",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\$ShellKey"
    )
    foreach ($path in $legacyPaths) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

$menuLabel = Get-MenuLabel
$shellKey = "OpenWithCursor"
$cursorExe = Find-CursorExecutable -CustomPath $CursorPath

if (-not $cursorExe) {
    Write-Host "ERROR: Cursor.exe not found." -ForegroundColor Red
    Write-Host 'Example: .\add-cursor-folder-context-menu.ps1 -CursorPath "C:\Users\NAME\AppData\Local\Programs\cursor\Cursor.exe"'
    exit 1
}

Write-Host ("Found Cursor: " + $cursorExe)
Remove-LegacyMenuEntries -ShellKey $shellKey

if (Test-IsAdmin) {
    Write-Host "Writing HKCR..." -ForegroundColor Cyan
    Install-BackgroundMenu -RootPrefix "Registry::HKEY_CLASSES_ROOT" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CLASSES_ROOT"
} else {
    Write-Host "WARNING: Not admin. Writing HKCU..." -ForegroundColor Yellow
    Install-BackgroundMenu -RootPrefix "Registry::HKEY_CURRENT_USER\Software\Classes" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CURRENT_USER\Software\Classes"
}

if (-not $SkipExplorerRestart) {
    Write-Host "Restarting Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
}

Write-Host "DONE." -ForegroundColor Green
Write-Host ("Registry: " + $installRoot + "\Directory\Background\shell\" + $shellKey)
Write-Host ("Menu: " + $menuLabel)
