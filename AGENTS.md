# AGENTS.md — aolun (敖论)

纯 Markdown skill 插件仓库（无可执行代码）。17 个 skill 为 AI agent 提供四层解剖 × 四维扫描 × 跨域重建 × 李敖风格战斗文本的方法论。

## 验证

```bash
npm test          # 或 bash tests/validate.sh
npm run test:win  # Windows
```

检查项：JSON 合法性、18 个必需文件存在性、所有 `skills/*/SKILL.md` 和 `commands/*.md` 的 YAML frontmatter（`name` + `description`）、`hooks/session-start` 可执行权限。新增 skill 时须同步更新 `tests/validate.sh` 的必需文件列表。

## Skill 依赖链（执行顺序不可打乱）

```
aolun-arming（路由器，会话启动）⚡
  → aolun-dissect-concept → aolun-inter-dissect-mechanism
    → aolun-inter-dissect-constraint → aolun-inter-dissect-interest
  → aolun-scan-orchestrator（并行 dispatch 四个扫描器）⚡
  → aolun-other-mountains → aolun-attack

aolun-ground（前置调研）⚡ → aolun-dissect-concept / aolun-build
aolun-build（正向规划）⚡
aolun-fileflow（文件持久化路由器，长文本/路径输入）⚡
  → aolun-prepare-docs（文档准备）⚡ → aolun-dissect-concept → ... → aolun-attack
```

解剖器严格顺序；扫描器由 orchestrator 并行；攻击文最后。

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
- **OpenCode skills 路径**：全局 `opencode.json` 的 `skills.paths` 指向 aolun 的 `skills/` 目录，无需 JS 插件
- **Bootstrap 注入**：通过 `AGENTS.md` 的 `instructions` 机制或手动 `skill` 加载 `aolun-arming`，不再依赖 JS 插件 prepend
- **fileflow 多源输入**：路径输入在长度检查之前被 arming 路由到 fileflow（路径通常 < 1500 字符）
- **`00-original.md` 无文件头** — 元数据在 `00-prep-meta.md` 或 `00-todolist.md`，行号引用才能对齐
- **引用格式**：单文件模式 `第<N>行："引用"`；目录模式 `<文件名>:<N>："引用"`
