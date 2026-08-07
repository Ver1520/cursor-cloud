# 移除 Windows 文件夹空白处右键菜单中的「用 Cursor 打开」
# 建议以管理员身份运行（可清理 HKCR 项）

$ErrorActionPreference = "Stop"
$shellKey = "OpenWithCursor"

$targets = @(
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\$shellKey",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\$shellKey",
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$shellKey",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell\$shellKey"
)

$removed = $false
foreach ($keyPath in $targets) {
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Recurse -Force
        Write-Host "已移除：$keyPath" -ForegroundColor Green
        $removed = $true
    }
}

if ($removed) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
    Write-Host "已移除文件夹空白处右键菜单，并已重启资源管理器。" -ForegroundColor Green
} else {
    Write-Host "未找到已注册的 Cursor 右键菜单项。" -ForegroundColor Yellow
}
