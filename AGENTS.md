# AGENTS.md — aolun (敖论)

纯 Markdown skill 插件仓库（无可执行代码）。9 个 skill 为 AI agent 提供两段式解剖/扫描 × 跨域重建 × 李敖风格战斗文本的方法论。

## 验证

```bash
npm test          # 或 bash tests/validate.sh
npm run test:win  # Windows
```

检查项：JSON 合法性、必需文件存在性、所有 `skills/*/SKILL.md` 和 `commands/*.md` 的 YAML frontmatter（`name` + `description`）、`hooks/session-start` 可执行权限。新增 skill 时须同步更新 `tests/validate.sh` 的必需文件列表。

## 路由

```
aolun-arming（会话入口路由器）⚡
  → aolun-dissect → aolun-scan
    → aolun-other-mountains（可选）→ aolun-attack

aolun-ground（前置调研）⚡ → aolun-dissect / aolun-build
aolun-build（正向规划）⚡
aolun-fileflow（文件持久化路由器，长文本/路径输入）⚡
  → aolun-prepare-docs（文档准备，可选）⚡
```

两段式：先 `aolun-dissect` 看清论断，再 `aolun-scan` 找弱点；长文本走 `aolun-fileflow` 的 Workflow 1/2/3（默认 Workflow 2）。

## 编辑规则

- 每个 SKILL.md 顶部必须有 `---` frontmatter，含 `name` 和 `description`（触发描述）
- frontmatter 由各平台自行剥离：OpenCode（原生 skill tool 自动剥离）、`hooks/session-start` 不剥离
- 内容双语（中文为主，英文为辅）
- 编辑后跑 `npm test`

## 多平台安装

- **OpenCode**: `opencode.json` 加 `skills.paths` 指向本地 `skills/` 目录（见 `.opencode/INSTALL.md`）
- **Claude Code**: `claude --plugin-dir .`
- **Cursor/Codex**: 见 `.cursor-plugin/` 和 `.codex/INSTALL.md`

## 易错点

- **`hooks/session-start` 必须 `chmod +x`** — validate.sh 会检查
- **Bootstrap 注入**：通过 `AGENTS.md` 的 `instructions` 机制或手动 `skill` 加载 `aolun-arming`
- **fileflow 多源输入**：路径输入在长度检查之前被 arming 路由到 fileflow（路径通常 < 1500 字符）
- **`00-original.md` 无文件头** — 元数据在 `00-prep-meta.md` 或 `00-todolist.md`，行号引用才能对齐
- **引用格式**：单文件模式 `第<N>行："引用"`；目录模式 `<文件名>:<N>："引用"`
