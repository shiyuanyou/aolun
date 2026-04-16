# AGENTS.md — aolun (敖论)

## 这仓库是什么

多平台 skill 插件，为 AI agent 提供系统化批判思维方法论：四层解剖（概念→机制→约束→利益）→ 四维扫描 → 跨域重建 → 李敖风格战斗文本生成。

## 仓库结构

| 路径 | 用途 |
|------|------|
| `skills/*/SKILL.md` | 17 个 skill 定义，每个含 YAML frontmatter（`name`、`description`）+ markdown 正文。入口 skill 用 `aolun-` 前缀，内部 skill 用 `aolun-inter-` 前缀 |
| `skills/aolun-prepare-docs/SKILL.md` | 新增：文档准备 skill，将任意输入（文本/文件/目录）转化为管线可消费的标准文档结构 |
| `skills/aolun-fileflow/SKILL.md` | 文件持久化分析路由器（长文本≥1500字符由 arming 自动路由，或用户直接调用）。支持多源输入（快照/引用模式） |
| `commands/*.md` | 斜杠命令定义（Claude Code / Cursor），同样需要 frontmatter |
| `hooks/` | 会话启动时注入 arming bootstrap；`session-start` 必须 `chmod +x` |
| `.opencode/plugins/aolun.js` | OpenCode 插件：注册 skills 路径 + 在首条消息注入 bootstrap |
| `.claude-plugin/` / `.cursor-plugin/` | 各平台插件清单 |
| `.codex/INSTALL.md` | Codex 手动安装说明 |
| `tests/validate.sh` / `validate.ps1` | 校验脚本 |
| `docs/specs/` | 设计规格文档 |
| `docs/superpowers/plans/` | 实施计划 |

## Skill 依赖链

```
aolun-arming（路由器，会话启动）⚡入口
  → aolun-dissect-concept → aolun-inter-dissect-mechanism
    → aolun-inter-dissect-constraint → aolun-inter-dissect-interest
  → aolun-scan-orchestrator（并行 dispatch 四个扫描器）⚡入口
  → aolun-other-mountains → aolun-attack

aolun-ground（前置调研）⚡入口
  → aolun-dissect-concept（带入阶段判断报告）
  → aolun-build（带入完整 ground 报告）

aolun-build（正向规划）⚡入口
  → (可选) aolun-other-mountains / aolun-attack

aolun-fileflow（文件持久化路由器）⚡入口
  → aolun-prepare-docs（文档准备，step 2.5）⚡入口
  → aolun-dissect-concept → ... → aolun-attack
  → 每步输出 → docs/aolun.skill/<date>-<brief>/<NN>-<skill>.md
```

解剖器必须按顺序执行。扫描器通过 `aolun-scan-orchestrator` 并行。攻击文最后。正向规划用 `aolun-ground → aolun-build`。

## 验证

```bash
npm test
# 或直接：
bash tests/validate.sh
# Windows：
npm run test:win
```

校验内容：JSON 文件合法性、必需文件存在性、所有 SKILL.md 和 command 文件的 YAML frontmatter、hooks 可执行权限。

**注意**：`validate.sh` 的必需文件清单未包含 `aolun-prepare-docs`、`aolun-fileflow`、`aolun-scan-orchestrator`。frontmatter 检查通过通配符覆盖它们，但如果这些文件被删除不会被标记为缺失。新增 skill 时记得更新验证脚本的必需文件列表。

## 编辑 skill 时的规则

- 每个 SKILL.md 顶部必须保留 `---` frontmatter，含 `name` 和 `description` 字段
- `description` 是 skill 的触发描述，必须清楚说明何时激活
- frontmatter 在使用前必须被剥离：OpenCode 插件 (`aolun.js`) 用正则剥离；`hooks/session-start` 不剥离（由平台处理）
- Skill 内容双语（中文为主，英文为辅），除非刻意删除一种
- 编辑后跑 `npm test` 验证

## 多平台安装

- **Claude Code**: `claude --plugin-dir .`
- **OpenCode**: `opencode.json` 的 plugin 数组里加 `"aolun@git+https://github.com/shiyuanyou/aolun.git"`
- **Cursor/Codex**: 见 `.cursor-plugin/` 和 `.codex/INSTALL.md`

## 易错点

- **`hooks/session-start` 必须 `chmod +x`**——验证脚本会检查
- **OpenCode 插件路径** (`../../skills`) 是相对于 `.opencode/plugins/aolun.js` 的，移动插件文件会破坏 skill 发现
- **Bootstrap 注入方式**：`aolun.js` 在首条用户消息前 prepend bootstrap 内容，不是替换
- **fileflow 多源输入**：粘贴走快照模式（copy 到任务目录），文件/目录路径走引用模式（直接读源路径）。路径输入在长度检查之前就被 arming 路由到 fileflow
- **fileflow 的 `00-original.md` 不含文件头**——元数据放在 `00-prep-meta.md` 或 `00-todolist.md`，行号引用才能对齐
- **扫描器引用格式**：粘贴/单文件模式用 `第<N>行："引用"`；目录模式用 `<文件名>:<N>："引用"`