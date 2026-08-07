$ErrorActionPreference = "Stop"
# Install Open-with-Cursor on folder BACKGROUND context menu.
# Admin PowerShell:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   irm https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1 | iex

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-CursorExecutable {
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
    # "用 Cursor 打开"
    return ([string][char]0x7528 + " Cursor " + [string][char]0x6253 + [string][char]0x5F00)
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
        [string]$CursorExe,
        [string]$MenuLabel,
        [string]$ShellKey
    )

    # Use PowerShell registry API to avoid reg.exe quoting bugs with spaces in paths
    $keyPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$ShellKey"
    $commandPath = Join-Path $keyPath "command"
    $commandValue = '"' + $CursorExe + '" "%V"'

    New-Item -Path $keyPath -Force | Out-Null
    Set-ItemProperty -LiteralPath $keyPath -Name "(default)" -Value $MenuLabel
    Set-ItemProperty -LiteralPath $keyPath -Name "Icon" -Value ($CursorExe + ",0")

    New-Item -Path $commandPath -Force | Out-Null
    Set-ItemProperty -LiteralPath $commandPath -Name "(default)" -Value $commandValue

    # Verify
    $written = (Get-ItemProperty -LiteralPath $commandPath)."(default)"
    if (-not $written) {
        throw "Failed to write registry command value."
    }
    Write-Host ("Command: " + $written)
}

function Restart-Explorer {
    Write-Host "Restarting Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
}

if (-not (Test-IsAdmin)) {
    Write-Host "Admin required. Requesting elevation..." -ForegroundColor Yellow
    $tempDir = Join-Path $env:TEMP "cursor-context-menu"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempScript = Join-Path $tempDir "install-selfcontained.ps1"

    # Prefer raw content already in memory when launched via irm|iex
    $sourceUrl = "https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1"
    $text = (Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing).Content
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tempScript, $text, $utf8NoBom)

    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"' + $tempScript + '"')
    ) -Wait
    return
}

$shellKey = "OpenWithCursor"
$menuLabel = Get-MenuLabel
$cursorExe = Find-CursorExecutable

if (-not $cursorExe) {
    Write-Host "ERROR: Cursor.exe not found." -ForegroundColor Red
    Write-Host ("Expected: " + (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"))
    exit 1
}

Write-Host ("Found Cursor: " + $cursorExe) -ForegroundColor Green
Remove-LegacyKeys -ShellKey $shellKey
Write-Host "Writing HKCR registry..." -ForegroundColor Cyan
Install-BackgroundMenu -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
Restart-Explorer

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host ("Registry: HKEY_CLASSES_ROOT\Directory\Background\shell\" + $shellKey)
Write-Host ("Menu label: " + $menuLabel)
Write-Host "Verify: open a folder, right-click empty space in the file list."
