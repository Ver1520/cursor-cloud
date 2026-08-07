# Windows：文件夹右键「用 Cursor 打开」

在 Windows 资源管理器中，为**文件夹**右键菜单添加「用 Cursor 打开」。

## 推荐方式（PowerShell，自动检测 Cursor 路径）

1. 打开 **PowerShell**（无需管理员）
2. 进入本目录并执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\add-cursor-folder-context-menu.ps1
```

若 Cursor 不在默认安装位置，可指定路径：

```powershell
.\add-cursor-folder-context-menu.ps1 -CursorPath "D:\Apps\Cursor\Cursor.exe"
```

## 备选方式（.reg 注册表文件）

1. 用记事本打开 `add-cursor-folder-context-menu.reg`
2. 将所有 `YOUR_USERNAME` 替换为你的 Windows 用户名
3. 双击该 `.reg` 文件并确认合并

## 移除

PowerShell：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\remove-cursor-folder-context-menu.ps1
```

或双击 `remove-cursor-folder-context-menu.reg`。

## 使用效果

| 操作 | 效果 |
| --- | --- |
| 右键点击文件夹 | 用 Cursor 打开该文件夹 |
| 在文件夹内空白处右键 | 用 Cursor 打开当前文件夹 |

## Windows 11 说明

Windows 11 默认使用精简右键菜单，自定义项可能出现在 **「显示更多选项」** 中。若需恢复经典完整菜单，可参考 [Microsoft 文档](https://learn.microsoft.com/en-us/answers/questions/2287432/article-restore-old-right-click-context-menu-in-wi)。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `add-cursor-folder-context-menu.ps1` | 添加菜单（推荐） |
| `remove-cursor-folder-context-menu.ps1` | 移除菜单 |
| `add-cursor-folder-context-menu.reg` | 注册表添加（需手动改用户名） |
| `remove-cursor-folder-context-menu.reg` | 注册表移除 |
