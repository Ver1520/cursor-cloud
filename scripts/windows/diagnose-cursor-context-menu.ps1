# 诊断 Windows 文件夹空白处「用 Cursor 打开」右键菜单
# 用法：PowerShell 中执行 .\diagnose-cursor-context-menu.ps1

$ErrorActionPreference = "Continue"
$shellKey = "OpenWithCursor"

Write-Host "========== Cursor 右键菜单诊断 ==========" -ForegroundColor Cyan
Write-Host ""

# 1. Cursor 路径
Write-Host "[1] 检查 Cursor 安装路径" -ForegroundColor Yellow
$paths = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
    "${env:ProgramFiles}\Cursor\Cursor.exe"
)
$found = $false
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "  找到：$p" -ForegroundColor Green
        $found = $true
    } else {
        Write-Host "  不存在：$p"
    }
}
if (-not $found) {
    Write-Host "  未找到 Cursor.exe，请先安装 Cursor。" -ForegroundColor Red
}
Write-Host ""

# 2. 注册表项
Write-Host "[2] 检查注册表项" -ForegroundColor Yellow
$regChecks = @(
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$shellKey",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\$shellKey"
)
$hasReg = $false
foreach ($regPath in $regChecks) {
    if (Test-Path $regPath) {
        $hasReg = $true
        $default = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue)."(default)"
        $cmdPath = Join-Path $regPath "command"
        $cmd = ""
        if (Test-Path $cmdPath) {
            $cmd = (Get-ItemProperty -Path $cmdPath -ErrorAction SilentlyContinue)."(default)"
        }
        Write-Host "  已注册：$regPath" -ForegroundColor Green
        Write-Host "    菜单名：$default"
        Write-Host "    命令：$cmd"
    } else {
        Write-Host "  未注册：$regPath"
    }
}
if (-not $hasReg) {
    Write-Host "  结论：尚未安装右键菜单，请运行 add-cursor-folder-context-menu.ps1" -ForegroundColor Red
}
Write-Host ""

# 3. 管理员权限
Write-Host "[3] 检查管理员权限" -ForegroundColor Yellow
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "  当前 PowerShell 已以管理员运行。" -ForegroundColor Green
} else {
    Write-Host "  当前未以管理员运行。Win10 建议使用管理员 PowerShell 安装。" -ForegroundColor Yellow
}
Write-Host ""

# 4. 操作提示
Write-Host "[4] 正确触发方式（Win10）" -ForegroundColor Yellow
Write-Host "  - 先双击进入某个文件夹"
Write-Host "  - 在右侧文件列表空白处右键（不要点在文件夹图标上）"
Write-Host "  - 不要在桌面或「此电脑」空白处测试（注册表项不同）"
Write-Host ""

Write-Host "========== 建议操作 ==========" -ForegroundColor Cyan
Write-Host "1. 右键 PowerShell → 以管理员身份运行"
Write-Host "2. cd 到 scripts\windows 目录"
Write-Host "3. Set-ExecutionPolicy -Scope Process Bypass -Force"
Write-Host "4. .\add-cursor-folder-context-menu.ps1"
Write-Host "5. 进入任意文件夹，在空白处右键验证"
