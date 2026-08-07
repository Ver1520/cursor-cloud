# 可在任意目录运行：下载并安装「用 Cursor 打开」右键菜单
# 推荐用法（管理员 PowerShell）：
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   irm https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1 | iex

$ErrorActionPreference = "Stop"

$branch = "cursor/folder-context-menu-cursor-7614"
$baseUrl = "https://raw.githubusercontent.com/Ver1520/cursor-cloud/$branch/scripts/windows"
$tempDir = Join-Path $env:TEMP "cursor-context-menu"
$scriptPath = Join-Path $tempDir "add-cursor-folder-context-menu.ps1"

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "正在下载安装脚本..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$baseUrl/add-cursor-folder-context-menu.ps1" -OutFile $scriptPath -UseBasicParsing

# 解除当前进程执行策略限制（避免 Restricted 拦截 .ps1）
Set-ExecutionPolicy -Scope Process Bypass -Force

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 始终用 Bypass 启动子进程执行，避免系统策略拦截
$psArgs = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath
)

if (-not (Test-IsAdmin)) {
    Write-Host "需要管理员权限，正在请求提升..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList $psArgs -Wait
} else {
    & powershell.exe @psArgs
    if ($LASTEXITCODE -ne 0) {
        throw "安装脚本执行失败，退出码：$LASTEXITCODE"
    }
}
