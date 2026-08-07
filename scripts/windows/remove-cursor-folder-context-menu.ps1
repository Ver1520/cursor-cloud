# 移除 Windows 文件夹空白处右键菜单中的「用 Cursor 打开」
# 用法：在 PowerShell 中执行
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\remove-cursor-folder-context-menu.ps1

$ErrorActionPreference = "Stop"

$shellKey = "OpenWithCursor"
$targets = @(
    "HKCU:\Software\Classes\Directory\shell\$shellKey",
    "HKCU:\Software\Classes\Directory\Background\shell\$shellKey"
)

$removed = $false
foreach ($keyPath in $targets) {
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Recurse -Force
        $removed = $true
    }
}

if ($removed) {
    Write-Host "已移除文件夹空白处右键菜单中的「用 Cursor 打开」。" -ForegroundColor Green
} else {
    Write-Host "未找到已注册的 Cursor 右键菜单项，无需移除。" -ForegroundColor Yellow
}
