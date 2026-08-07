# 为 Windows 文件夹空白处右键菜单添加「用 Cursor 打开」
# 用法：在 PowerShell 中执行
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\add-cursor-folder-context-menu.ps1

param(
    [string]$CursorPath = ""
)

$ErrorActionPreference = "Stop"

if (-not $CursorPath) {
    # 常见 Cursor 安装路径（按优先级）
    $candidatePaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
        "${env:ProgramFiles}\Cursor\Cursor.exe",
        "${env:ProgramFiles(x86)}\Cursor\Cursor.exe"
    )

    $CursorPath = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $CursorPath -or -not (Test-Path $CursorPath)) {
    Write-Error @"
未找到 Cursor.exe。请确认已安装 Cursor，或将路径作为参数传入：
  .\add-cursor-folder-context-menu.ps1 -CursorPath 'C:\path\to\Cursor.exe'
"@
}

$cursorExe = (Resolve-Path $CursorPath).Path
$menuLabel = "用 Cursor 打开"
$shellKey = "OpenWithCursor"
$keyPath = "HKCU:\Software\Classes\Directory\Background\shell\$shellKey"

# 仅注册文件夹空白处右键（Directory\Background），不包含选中文件夹时的菜单
New-Item -Path $keyPath -Force | Out-Null
Set-ItemProperty -Path $keyPath -Name "(Default)" -Value $menuLabel
Set-ItemProperty -Path $keyPath -Name "Icon" -Value "$cursorExe,0"

$commandKey = Join-Path $keyPath "command"
New-Item -Path $commandKey -Force | Out-Null
Set-ItemProperty -Path $commandKey -Name "(Default)" -Value "`"$cursorExe`" `"%V`""

# 若之前添加过「选中文件夹」菜单，一并清理
$legacyKey = "HKCU:\Software\Classes\Directory\shell\$shellKey"
if (Test-Path $legacyKey) {
    Remove-Item -Path $legacyKey -Recurse -Force
}

Write-Host "已成功添加文件夹空白处右键菜单项：$menuLabel" -ForegroundColor Green
Write-Host "Cursor 路径：$cursorExe"
Write-Host ""
Write-Host "说明：" -ForegroundColor Yellow
Write-Host "  - 在文件夹内空白处右键 → 用 Cursor 打开当前文件夹"
Write-Host "  - 不会在「选中文件夹」的右键菜单中出现"
Write-Host "  - Windows 11 可能需点击「显示更多选项」才能看到该菜单项"
