@echo off
chcp 65001 >nul
echo 正在请求管理员权限并安装「用 Cursor 打开」右键菜单...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0add-cursor-folder-context-menu.ps1\"'"

pause
