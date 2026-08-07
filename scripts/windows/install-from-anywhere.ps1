# Install "Open with Cursor" on folder background context menu (Win10/Win11)
# Usage (Admin PowerShell):
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   irm https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1 | iex
#
# ASCII-only script body to avoid Windows PowerShell encoding parse errors.

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

    if ($env:ProgramFiles -ne ${env:ProgramFiles(x86)}) {
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
    # Menu text via codepoints (encoding-safe for WinPS)
    return (
        [string][char]0x7528 +
        " Cursor " +
        [string][char]0x6253 +
        [string][char]0x5F00
    )
}

function Remove-LegacyKeys {
    param([string]$ShellKey)

    $paths = @(
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\$ShellKey",
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\$ShellKey",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\$ShellKey"
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

function Install-BackgroundMenu {
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

function Restart-Explorer {
    Write-Host "Restarting Explorer to refresh context menu..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
}

# If not admin, relaunch elevated and re-run this same script content via temp file (UTF8 BOM)
if (-not (Test-IsAdmin)) {
    Write-Host "Admin required. Requesting elevation..." -ForegroundColor Yellow

    $tempDir = Join-Path $env:TEMP "cursor-context-menu"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempScript = Join-Path $tempDir "install-selfcontained.ps1"

    # Prefer MyInvocation path when run as -File; otherwise rebuild from web on elevated process
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        Copy-Item -LiteralPath $PSCommandPath -Destination $tempScript -Force
    } else {
        $url = "https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1"
        $bytes = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
        # Write UTF-8 BOM so Windows PowerShell parses correctly
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($tempScript, $bytes, $utf8Bom)
    }

    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$tempScript`""
    ) -Wait
    return
}

$shellKey = "OpenWithCursor"
$menuLabel = Get-MenuLabel
$cursorExe = Find-CursorExecutable

if (-not $cursorExe) {
    Write-Host "ERROR: Cursor.exe not found." -ForegroundColor Red
    Write-Host "Install Cursor first, or pass -CursorPath when using the local script."
    Write-Host ("Expected: " + (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"))
    exit 1
}

Write-Host "Found Cursor: $cursorExe" -ForegroundColor Green

Remove-LegacyKeys -ShellKey $shellKey
Write-Host "Writing HKCR registry (Win10)..." -ForegroundColor Cyan
Install-BackgroundMenu -RegRoot "HKEY_CLASSES_ROOT" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
Restart-Explorer

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host "Registry: HKEY_CLASSES_ROOT\Directory\Background\shell\$shellKey"
Write-Host "Menu label: $menuLabel"
Write-Host ""
Write-Host "How to verify:" -ForegroundColor Yellow
Write-Host "  1. Open any folder (enter it)"
Write-Host "  2. Right-click empty space in the file list"
Write-Host "  3. You should see the Cursor menu item"
