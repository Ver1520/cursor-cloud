---
name: install-cursor-folder-context-menu
description: >
  Install, repair, diagnose, or uninstall the Windows Explorer folder BACKGROUND
  context menu item "用 Cursor 打开" / Open with Cursor. Use when the user asks to
  add Cursor to the right-click menu on empty folder space, Directory\Background\shell
  registry, Explorer context menu for folder background (not selected folder),
  or run scripts under scripts/windows/ (install-from-anywhere.ps1,
  add-cursor-folder-context-menu.ps1, diagnose-cursor-context-menu.ps1).
compatibility: Windows 10/11; requires Admin PowerShell for HKCR install.
---

# Install Cursor folder-background context menu (Windows)

## Goal

Add **「用 Cursor 打开」** only when the user right-clicks **empty space inside a folder**
(`Directory\Background\shell`). Do **not** add it for selected folder icons
(`Directory\shell`).

Cursor has **no Settings toggle** for this; registry install is required.

## Proven one-liner (preferred on any PC)

Tell the user to open **Admin PowerShell** (Win+X → Windows PowerShell (Admin)) and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
irm https://raw.githubusercontent.com/Ver1520/cursor-cloud/cursor/folder-context-menu-cursor-7614/scripts/windows/install-from-anywhere.ps1 | iex
```

If GitHub `raw` serves a stale branch cache, pin a known-good commit SHA instead of the branch name in the URL.

Success output looks like:

```text
Found Cursor: C:\Users\...\AppData\Local\Programs\cursor\Cursor.exe
Writing HKCR registry...
Command: "C:\Users\...\Cursor.exe" "%V"
Restarting Explorer...
DONE.
```

## Verify

1. Double-click into any folder (must enter it).
2. Right-click **empty space** in the file list.
3. Expect menu item **用 Cursor 打开**.

Will **not** appear when:

- Right-clicking a folder icon/name
- Right-clicking Desktop background
- Right-clicking This PC root background

## Uninstall

Admin PowerShell:

```powershell
Remove-Item -Recurse -Force "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCursor" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\OpenWithCursor" -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer
```

Or run `scripts/windows/remove-cursor-folder-context-menu.ps1` as Admin.

## Local repo scripts

| File | Role |
| --- | --- |
| `scripts/windows/install-from-anywhere.ps1` | Self-contained remote installer (use this) |
| `scripts/windows/add-cursor-folder-context-menu.ps1` | Local installer |
| `scripts/windows/diagnose-cursor-context-menu.ps1` | Diagnostics |
| `scripts/windows/install-context-menu.cmd` | Double-click elevating launcher |
| `scripts/windows/README.md` | Human docs |

Default Cursor path:

`%LOCALAPPDATA%\Programs\cursor\Cursor.exe`

## Hard-won rules (do not regress)

1. **Target key**: only `HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCursor` (+ `command` subkey). Win10 needs **Admin → HKCR**; HKCU-only often does nothing.
2. **Command value**: `"<Cursor.exe full path>" "%V"` (background uses `%V`).
3. **Never use `reg.exe` for the command string** when the user profile path has spaces (e.g. `Versatile Dragon`). Use PowerShell registry API:

   ```powershell
   $key = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWithCursor"
   New-Item $key -Force | Out-Null
   Set-ItemProperty $key "(default)" -Value $menuLabel
   Set-ItemProperty $key "Icon" -Value ($cursorExe + ",0")
   New-Item (Join-Path $key "command") -Force | Out-Null
   Set-ItemProperty (Join-Path $key "command") "(default)" -Value ('"' + $cursorExe + '" "%V"')
   ```

4. **Encoding / `irm | iex`**:
   - Script body must be ASCII-safe (no raw Chinese in executable strings).
   - Menu text via codepoints: `[char]0x7528 + " Cursor " + [char]0x6253 + [char]0x5F00` → `用 Cursor 打开`.
   - **No UTF-8 BOM** on scripts meant for `irm | iex` (BOM breaks first-line `#` comments; e.g. `(Win10/Win11)` gets executed).
   - First line should be real code: `$ErrorActionPreference = "Stop"`.
5. **ExecutionPolicy**: always `Set-ExecutionPolicy -Scope Process Bypass -Force` before running; elevated child processes need `-ExecutionPolicy Bypass` too.
6. After install, restart Explorer (`Stop-Process explorer; Start-Process explorer`).
7. Do **not** tell users to `cd scripts\windows` from `C:\Windows\system32` unless the repo is actually there — use the `irm | iex` path instead.
8. Agent runs in Linux cloud VMs cannot apply this registry change on the user's Windows PC; give the user the Admin PowerShell commands.

## Agent checklist on a new Windows PC

- [ ] Confirm OS is Windows
- [ ] Give Admin PowerShell one-liner (`install-from-anywhere.ps1`)
- [ ] Ask user to paste full terminal output
- [ ] If failure: check Cursor path, admin elevation, ExecutionPolicy, path spaces, raw URL cache
- [ ] Guide verification on folder **background** only
- [ ] Offer uninstall commands if requested
