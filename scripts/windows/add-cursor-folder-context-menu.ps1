# Add "Open with Cursor" to folder BACKGROUND context menu (Win10/Win11)
# ASCII-only body to avoid Windows PowerShell encoding parse errors.
# Usage (Admin PowerShell):
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\add-cursor-folder-context-menu.ps1

param(
    [string]$CursorPath = "",
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = "Stop"

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
    return (
        [string][char]0x7528 +
        " Cursor " +
        [string][char]0x6253 +
        [string][char]0x5F00
    )
}

function Install-ContextMenu {
    param(
        [string]$RegRoot,
        [string]$CursorExe,
        [string]$MenuLabel,
        [string]$ShellKey
    )

    $keyPath = "$RegRoot\Directory\Background\shell\$ShellKey"
    $commandValue = "`"$CursorExe`" `"%V`""

    & reg.exe ADD $keyPath /ve /d $MenuLabel /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "reg ADD failed: $keyPath" }

    & reg.exe ADD $keyPath /v Icon /d "$CursorExe,0" /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "reg ADD Icon failed: $keyPath" }

    & reg.exe ADD "$keyPath\command" /ve /d $commandValue /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "reg ADD command failed: $keyPath\command" }
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

function Restart-ExplorerIfNeeded {
    if (-not $SkipExplorerRestart) {
        Write-Host "Restarting Explorer..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
    }
}

$menuLabel = Get-MenuLabel
$shellKey = "OpenWithCursor"
$cursorExe = Find-CursorExecutable -CustomPath $CursorPath

if (-not $cursorExe) {
    Write-Host "ERROR: Cursor.exe not found." -ForegroundColor Red
    Write-Host "Example:"
    Write-Host '  .\add-cursor-folder-context-menu.ps1 -CursorPath "C:\Users\NAME\AppData\Local\Programs\cursor\Cursor.exe"'
    exit 1
}

Write-Host "Found Cursor: $cursorExe"
Remove-LegacyMenuEntries -ShellKey $shellKey

if (Test-IsAdmin) {
    Write-Host "Writing HKCR (recommended on Win10)..." -ForegroundColor Cyan
    Install-ContextMenu -RegRoot "HKEY_CLASSES_ROOT" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CLASSES_ROOT"
} else {
    Write-Host "WARNING: Not admin. Writing HKCU (may not work on Win10)." -ForegroundColor Yellow
    Install-ContextMenu -RegRoot "HKEY_CURRENT_USER\Software\Classes" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CURRENT_USER\Software\Classes"
}

Restart-ExplorerIfNeeded

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host "Registry: $installRoot\Directory\Background\shell\$shellKey"
Write-Host "Menu: $menuLabel"
Write-Host "Verify: open a folder, right-click empty space in the file list."
