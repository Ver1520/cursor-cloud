# 为 Windows 文件夹空白处右键菜单添加「用 Cursor 打开」（Win10/Win11）
# 用法：
#   右键「以管理员身份运行」PowerShell，然后执行：
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\add-cursor-folder-context-menu.ps1

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
        if (Test-Path $CustomPath) {
            return (Resolve-Path $CustomPath).Path
        }
        return $null
    }

    $candidatePaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
        "${env:ProgramFiles}\Cursor\Cursor.exe",
        "${env:ProgramFiles(x86)}\Cursor\Cursor.exe"
    )

    foreach ($path in $candidatePaths) {
        if (Test-Path $path) {
            return (Resolve-Path $path).Path
        }
    }

    $cursorCmd = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cursorCmd -and $cursorCmd.Source -and (Test-Path $cursorCmd.Source)) {
        return (Resolve-Path $cursorCmd.Source).Path
    }

    return $null
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

    reg.exe ADD "$keyPath" /ve /d "$MenuLabel" /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "写入注册表失败：$keyPath" }

    reg.exe ADD "$keyPath" /v Icon /d "$CursorExe,0" /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "写入 Icon 失败：$keyPath" }

    reg.exe ADD "$keyPath\command" /ve /d $commandValue /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "写入 command 失败：$keyPath\command" }
}

function Remove-LegacyMenuEntries {
    param([string]$ShellKey)

    $legacyPaths = @(
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\$ShellKey",
        "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\$ShellKey",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\$ShellKey"
    )

    foreach ($path in $legacyPaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force
        }
    }
}

function Restart-ExplorerIfNeeded {
    if (-not $SkipExplorerRestart) {
        Write-Host "正在重启资源管理器以刷新右键菜单..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
    }
}

# Win10 推荐使用 HKCR（需管理员）；无管理员时回退 HKCU
$menuLabel = "用 Cursor 打开"
$shellKey = "OpenWithCursor"
$cursorExe = Find-CursorExecutable -CustomPath $CursorPath

if (-not $cursorExe) {
    Write-Host "错误：未找到 Cursor.exe。" -ForegroundColor Red
    Write-Host "请确认已安装 Cursor，或使用 -CursorPath 指定路径，例如："
    Write-Host "  .\add-cursor-folder-context-menu.ps1 -CursorPath 'C:\Users\你\AppData\Local\Programs\cursor\Cursor.exe'"
    exit 1
}

Write-Host "检测到 Cursor：$cursorExe"

Remove-LegacyMenuEntries -ShellKey $shellKey

if (Test-IsAdmin) {
    Write-Host "以管理员身份写入 HKCR 注册表（Win10 推荐）..." -ForegroundColor Cyan
    Install-ContextMenu -RegRoot "HKEY_CLASSES_ROOT" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CLASSES_ROOT"
} else {
    Write-Host "警告：当前未以管理员运行，将写入 HKCU（Win10 上可能不生效）。" -ForegroundColor Yellow
    Write-Host "建议：双击 install-context-menu.cmd，或以管理员身份运行 PowerShell。" -ForegroundColor Yellow
    Install-ContextMenu -RegRoot "HKEY_CURRENT_USER\Software\Classes" -CursorExe $cursorExe -MenuLabel $menuLabel -ShellKey $shellKey
    $installRoot = "HKEY_CURRENT_USER\Software\Classes"
}

Restart-ExplorerIfNeeded

Write-Host ""
Write-Host "安装完成。" -ForegroundColor Green
Write-Host "注册表位置：$installRoot\Directory\Background\shell\$shellKey"
Write-Host ""
Write-Host "如何验证（Win10）：" -ForegroundColor Yellow
Write-Host "  1. 打开任意文件夹（双击进入，不要只在外层列表里右键）"
Write-Host "  2. 在右侧文件列表的空白处右键"
Write-Host "  3. 应看到「$menuLabel」"
Write-Host ""
Write-Host "若仍看不到，请运行：.\diagnose-cursor-context-menu.ps1"
