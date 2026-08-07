# 可在任意目录运行：下载并安装「用 Cursor 打开」右键菜单
# 用法（管理员 PowerShell）：
#   irm https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1 | iex

$ErrorActionPreference = "Stop"

$branch = "cursor/folder-context-menu-cursor-7614"
$baseUrl = "https://raw.githubusercontent.com/Ver1520/cursor-cloud/$branch/scripts/windows"
$tempDir = Join-Path $env:TEMP "cursor-context-menu"
$scriptPath = Join-Path $tempDir "add-cursor-folder-context-menu.ps1"

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "正在下载安装脚本..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$baseUrl/add-cursor-folder-context-menu.ps1" -OutFile $scriptPath -UseBasicParsing

# 若当前不是管理员，则提升权限后执行
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "需要管理员权限，正在请求提升..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`""
    ) -Wait
    exit
}

& $scriptPath
