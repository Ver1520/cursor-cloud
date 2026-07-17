# cursor-cloud

用于 Cursor Cloud Agents 的工作仓库。

## 本地状态

- 远程：`https://github.com/Ver1520/cursor-cloud.git`
- 默认分支：`main`

## 启用 Cloud Agents（需在 Dashboard 完成）

1. 打开 [Cursor Integrations](https://cursor.com/dashboard?tab=integrations)，连接 GitHub，并授予本仓库访问权限（All 或 Selected → `Ver1520/cursor-cloud`）
2. 打开 [Cloud Agents](https://cursor.com/agents)，为本仓库创建 Environment（可用 Agent 引导式安装，完成后保存 snapshot）
3. 在 Secrets 中添加运行/测试所需的环境变量（不要提交到 Git）
4. 在 Cursor Desktop 的 Agent 输入框下方选择 **Cloud**，或在 Web / `@cursor` 评论中启动云端任务

## 仓库内配置

| 文件 | 作用 |
| --- | --- |
| `.cursor/environment.json` | Cloud Agent 环境安装命令（可后续改为 snapshot / Dockerfile） |
| `AGENTS.md` | 给 Agent 的仓库级指令（含 Cloud 专用说明） |

参考文档：

- [Cloud Agents](https://cursor.com/docs/cloud-agent)
- [Cloud Environment Setup](https://cursor.com/docs/cloud-agent/setup)
- [GitHub Integration](https://cursor.com/docs/integrations/github)
