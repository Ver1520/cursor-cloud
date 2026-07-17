# cursor-cloud

本仓库用于 Cursor Cloud Agents 开发与验证。

## 本地约定

- 使用 Windows 命令；不要使用 Linux 专用指令
- 代码注释使用中文
- 除删除文件外，其余操作直接执行，不要反复征求确认
- 禁止使用过时 API
- 未明确要求时不要创建 git commit；不要擅自 push

## Cursor Cloud specific instructions

- Cloud Agent 运行在隔离的 Ubuntu 虚拟机上，会从 GitHub 克隆本仓库并在独立分支上工作
- 当前仓库几乎为空，新增依赖或技术栈后，请同步更新 `.cursor/environment.json` 的 `install` 命令（例如 `npm install` / `pip install -r requirements.txt`）
- 密钥与 API Key 不要写入仓库；放到 Cursor Dashboard → Cloud Agents → Secrets
- 需要可复用的环境快照时，在 [Cloud Agents Dashboard](https://cursor.com/agents) 完成一次引导式环境配置后保存 snapshot，再把 snapshot id 写入 `.cursor/environment.json`
- 任务完成后推送分支，便于本地或 PR 接手继续开发
