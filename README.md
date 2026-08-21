# 敖论 · aolun

> "我批评人，是有凭据的。我的批评一剑封喉，因为我把他们的底裤都翻出来了。"
> —— 李敖

「敖论」把任何技术论断拆底朝天，然后指出更好的方向——不是风格模仿，是真正有杀伤力的工程判断。

---

## 架构

两段式核心 + fileflow 默认流程：

```
aolun-arming（会话入口路由器）⚡
  ├─ aolun-dissect   解剖：看清论断声称什么、凭什么成立、在什么条件下、谁在推
  ├─ aolun-scan      扫描：找未被解剖覆盖的弱点（逻辑/工程/历史/动机）
  ├─ aolun-other-mountains  跨领域解法（可选）
  └─ aolun-attack    整合成李敖风格战斗文本
```

配套 skill：
- `aolun-ground` — 进入解剖/建设前先建立最小感性认识、判断所处阶段
- `aolun-build` — 正向建设（技术方案/产品路径/团队实践）的实践规划
- `aolun-prepare-docs` — 把文本/路径转成标准文档结构（快照/引用），fileflow 可选前置
- `aolun-fileflow` — 长文本/方案的文件持久化路由器，多源输入、Workflow 1/2/3

## 工作流（在 `aolun-fileflow/SKILL.md`）

| 工作流 | 流程 | 命令 |
|--------|------|------|
| Workflow 1 快速狙击 | `01-dissect`（轻量）→ `02-attack`（50–200 字） | `/aolun-quick-shot` |
| Workflow 2 标准拆解（默认） | `01-dissect → 02-scan → 03-other-mountains（可选）→ 04-attack → 99-final` | — |
| Workflow 3 底朝天全拆 | `01-dissect → 02-scan → 02b-deep-verify（可选）→ 03-other-mountains（可选）→ 04-attack → 99-final` | `/aolun-full-teardown` |
| 正向建设 | `aolun-ground → aolun-build` | — |

---

## 验证

```bash
bash tests/validate.sh    # 或 npm test
npm run test:win          # Windows
```

---

## 安装

- **Claude Code**：`git clone https://github.com/shiyuanyou/aolun && cd aolun && claude --plugin-dir .`
- **OpenCode**：`opencode.json` 加 `skills.paths` 指向本地 `skills/` 目录（见 `.opencode/INSTALL.md`）
- **Cursor / Codex**：见 `.cursor-plugin/` 和 `.codex/INSTALL.md`

---

## 编辑规则

- 每个 `skills/*/SKILL.md` 顶部必须有 `---` frontmatter，含 `name` 和 `description`
- 新增 skill 时同步更新 `tests/validate.sh` 的必需文件列表
- 编辑后跑 `bash tests/validate.sh` 或 `npm test`

---

## 许可证

MIT License
