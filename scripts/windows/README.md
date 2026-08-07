# Windows：文件夹空白处右键「用 Cursor 打开」

在 Windows 资源管理器中，仅在**文件夹内空白处**右键时显示「用 Cursor 打开」。

## Win10 一键安装（推荐）

1. 进入 `scripts\windows` 目录
2. **双击** `install-context-menu.cmd`
3. 在 UAC 提示中点击「是」（需要管理员权限）
4. 安装完成后：**双击进入任意文件夹**，在右侧空白处右键验证

## 手动安装（PowerShell）

```powershell
# 必须以管理员身份打开 PowerShell
cd scripts\windows
Set-ExecutionPolicy -Scope Process Bypass -Force
.\add-cursor-folder-context-menu.ps1
```

若 Cursor 不在默认路径：

```powershell
.\add-cursor-folder-context-menu.ps1 -CursorPath "D:\Apps\Cursor\Cursor.exe"
```

## 菜单没出现？先运行诊断

```powershell
.\diagnose-cursor-context-menu.ps1
```

### Win10 常见问题

| 问题 | 解决 |
| --- | --- |
| 未以管理员安装 | Win10 需写入 `HKCR`，请用 `install-context-menu.cmd` 或管理员 PowerShell |
| 右键位置不对 | 必须**进入文件夹内部**，在文件列表空白处右键 |
| 安装后未刷新 | 脚本会自动重启资源管理器；仍无效则注销重登 |
| 找不到 Cursor | 用 `-CursorPath` 指定 `Cursor.exe` 完整路径 |

### 正确测试方式

```
此电脑 → 打开 D:\某个项目文件夹 → 在右侧空白处右键 → 应出现「用 Cursor 打开」
```

以下位置**不会**出现该菜单：
- 在文件夹图标上右键（那是选中文件夹的菜单）
- 在桌面空白处右键
- 在「此电脑」根目录空白处右键

## 备选：.reg 注册表文件

1. 编辑 `add-cursor-folder-context-menu.reg`，替换 `YOUR_USERNAME`
2. **右键 → 合并**（需管理员确认）
3. 重启资源管理器或注销

## 移除

双击 `install-context-menu.cmd` 同目录下，以管理员运行：

```powershell
.\remove-cursor-folder-context-menu.ps1
```

或双击 `remove-cursor-folder-context-menu.reg`。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `install-context-menu.cmd` | Win10 一键安装（推荐） |
| `add-cursor-folder-context-menu.ps1` | 安装脚本 |
| `diagnose-cursor-context-menu.ps1` | 诊断脚本 |
| `remove-cursor-folder-context-menu.ps1` | 移除脚本 |
| `*.reg` | 注册表导入备选 |
