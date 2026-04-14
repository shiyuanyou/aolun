# aolun-fileflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `aolun-fileflow` skill 并修改 `aolun-arming`，让长文本分析（≥1500字符）自动路由到文件持久化模式，防止 compact 导致上下文丢失。

**Architecture:** 两个文件变更：① `aolun-arming` 在调度规则前增加长度判断前置块；② 新建 `skills/aolun-fileflow/SKILL.md`，实现文件持久化分析路由器（创建任务目录、逐步执行各 skill、每步落盘并暂停询问、最终整合）。

**Tech Stack:** 纯 Markdown skill 文件，无可执行代码；文件操作由宿主 agent 的工具完成（Bash/grep/sed）。

---

### Task 1：修改 `aolun-arming`，插入长度判断前置块

**Files:**
- Modify: `skills/aolun-arming/SKILL.md`（在第59行 `## 调度规则` 之前插入）

- [ ] **Step 1：在 `## 调度规则` 之前插入前置判断块**

在 `skills/aolun-arming/SKILL.md` 第58行（`---` 分隔线）和第59行（`## 调度规则`）之间插入以下内容：

```markdown

## 前置：输入长度判断

收到需要拆解的文本后，**第一步**先判断长度：

| 条件 | 路径 |
|------|------|
| 输入文本字符数 < 1500 | 继续走下方调度规则（内存执行模式） |
| 输入文本字符数 ≥ 1500 | 移交给 `aolun-fileflow`（文件持久化模式） |

> 判断方法：目测或计数均可。中文500字约等于1500字符，英文250词约等于1500字符，作为参考基准。

长文本强制走 fileflow 的原因：长文本分析产生的中间态报告量大，极易触发 compact，导致上下文丢失。文件落盘是唯一可靠的防御。

---

```

- [ ] **Step 2：验证 frontmatter 完整性**

运行：
```bash
head -10 "skills/aolun-arming/SKILL.md"
```
预期输出：`---` 开头，包含 `name:` 和 `description:` 字段，结构未破坏。

- [ ] **Step 3：运行验证脚本**

```bash
npm test
```
预期：所有检查通过，无 frontmatter 报错。

- [ ] **Step 4：提交**

```bash
git add skills/aolun-arming/SKILL.md
git commit -m "feat: add length-based routing to aolun-arming"
```

---

### Task 2：新建 `skills/aolun-fileflow/SKILL.md`

**Files:**
- Create: `skills/aolun-fileflow/SKILL.md`

- [ ] **Step 1：创建目录和文件**

```bash
mkdir -p "skills/aolun-fileflow"
```

然后写入以下完整内容到 `skills/aolun-fileflow/SKILL.md`：

```markdown
---
name: aolun-fileflow
description: |
  ⚡入口 skill。当分析文本字符数 ≥ 1500 时由 aolun-arming 自动路由，或用户直接调用。
  基于文件持久化的逐步分析路由器：每个 skill 的输出落盘为独立文件，每步完成后暂停等待
  用户确认，最终整合为完整分析文档。防止长文本分析中的 compact 上下文丢失。
  English: Entry skill. Auto-routed from aolun-arming when input ≥ 1500 chars, or invoked directly.
  File-based persistent analysis router: each skill output is saved to disk, pauses after each step
  for user confirmation, and integrates into a final document. Prevents context loss from compaction.
---

# 文件持久化分析路由器

> "打持久战，要有根据地。"

长文本分析是持久战。没有根据地（文件落盘），中间态就会在 compact 中消失。
这个 skill 的核心任务：**把每一步的输出存下来，然后等你说继续。**

---

## Part 1：启动阶段

收到输入文本后，依次完成：

### 1. 提取 brief

从输入文本**前50字符**生成任务目录的 `<brief>` 部分：
- 去除标点、括号、引号等特殊字符
- 空格替换为连字符
- 转小写
- 截断到约20字符

示例：`"大语言模型的 Scaling Law 已经触顶了吗？本文认为..."` → `da-yuyan-moxing-scaling-law`

### 2. 创建任务目录

```
docs/aolun.skill/<yyyy-mm-dd>-<brief>/
```

使用当天日期（格式：`2026-04-14`）。

### 3. 询问工作流

展示以下选择，等待用户回复：

```
即将开始文件持久化分析。请选择工作流：

[2] Workflow 2 标准拆解（推荐）
    四层解剖 → 并行扫描 → 可选他山之石 → 攻击文
    适合：一篇完整的技术文章或方案

[3] Workflow 3 底朝天全拆
    同上，但扫描后增加深度验证轮次
    适合：重要行业论断或主流方法论

任务目录已创建：docs/aolun.skill/<yyyy-mm-dd>-<brief>/
```

### 4. 展示执行计划

根据用户选择，展示步骤序列（见 Part 3），等待用户确认开始。

---

## Part 2：逐步执行规则

**每个步骤的统一执行模式：**

```
① 调用当前步骤对应的 skill
   （传入：原始文本 + 上一步输出文件路径作为上下文）

② 将 skill 完整输出写入对应编号文件
   文件路径：docs/aolun.skill/<yyyy-mm-dd>-<brief>/<NN>-<skill-name>.md

③ 从文件中提取摘要（不重新总结，直接 grep）
   提取规则：找到文件中最后一个以【开头的块，取该块内最后一个非空行
   参考命令：
     LAST_BLOCK=$(grep -n "^【" <file> | tail -1 | cut -d: -f1)
     tail -n +$LAST_BLOCK <file> | grep -v "^$" | tail -1

④ 在对话中展示摘要（不展示全文）

⑤ 暂停，显示操作提示：

   ✓ 已保存：<文件名>
   摘要：<提取的摘要行>

   下一步：<NN+1>-<skill-name>
   [继续] 执行下一步
   [修改] 提出修改意见后重新执行，覆盖写入
   [跳过] 跳过下一步
   [结束] 在此停止

⑥ 等待用户回复后再继续
```

**修改时：** 重新执行当前 skill（将用户修改意见作为附加指令传入），覆盖写入文件，再次展示摘要，再次暂停询问。

**跳过时：** 在下一个文件的头部注释中记录：`> 注：<NN>-<skill-name> 已跳过`，继续执行再下一步。

---

## Part 3：步骤序列定义

### Workflow 2：标准拆解

| 步骤文件 | 调用 Skill | 是否必须 |
|---------|-----------|---------|
| `01-dissect-concept.md` | `aolun-dissect-concept` | 必须 |
| `02-dissect-mechanism.md` | `aolun-inter-dissect-mechanism` | 必须 |
| `03-dissect-constraint.md` | `aolun-inter-dissect-constraint` | 必须 |
| `04-dissect-interest.md` | `aolun-inter-dissect-interest` | 必须 |
| `05-scan-summary.md` | `aolun-scan-orchestrator` | 必须 |
| `06-other-mountains.md` | `aolun-other-mountains` | 可选（执行前询问用户） |
| `07-attack.md` | `aolun-attack` | 必须 |
| `99-final-<slug>.md` | — | 用户选择整合时生成 |

执行到 `06` 前，询问：`是否需要引入跨领域解法？[是/否]`

### Workflow 3：底朝天全拆

同 Workflow 2，在 `05-scan-summary.md` 之后增加：

| 步骤文件 | 调用 Skill | 说明 |
|---------|-----------|------|
| `05b-scan-deep-verify.md` | `aolun-scan-logic` / `aolun-scan-engineering` | 对扫描结果中证据不足的条目补充深度调查 |

---

## Part 4：文件格式规范

### 中间态文件格式

每个编号文件的内容格式：

```markdown
# <skill名称> — <任务brief>

> 执行时间：<yyyy-mm-dd HH:MM>
> 输入来源：原始文本 / <上一步文件名>
> 状态：完成 / 已修改（第N次）

---

<skill 完整输出>
```

### 摘要提取规则

skill 的输出末尾包含结构化报告块（如 `【概念层解剖报告】`、`【逻辑弱点扫描报告】`）。
提取该块内最后一个非空行作为摘要展示。

如果文件中没有找到 `【` 开头的块，则提取文件最后5行中第一个非空行。

---

## Part 5：整合规则

所有步骤完成（或用户选择提前整合）后：

### 确认 slug

询问用户：`最终文件名 slug？（直接回车使用 <brief>）`

### 写入 `99-final-<slug>.md`

```markdown
# <slug> — 完整分析

> 整合时间：<yyyy-mm-dd HH:MM>
> 任务目录：docs/aolun.skill/<yyyy-mm-dd>-<brief>/
> 包含步骤：01-dissect-concept, 02-dissect-mechanism, ...（列出实际包含的步骤）

---

<按序拼接各步骤完整内容，各步骤间用 --- 分隔>

---

## 整体摘要

> 从各步骤文件中提取的综合判断：

- **概念层**：<01 文件的概念层综合判断行>
- **机制层**：<02 文件的机制层综合判断行>
- **约束层**：<03 文件的约束层综合判断行>
- **利益层**：<04 文件的利益层综合判断行>
- **扫描综合**：<05 文件的最致命一击>
- **攻击文定性**：<07 文件的定性结论行>
```

整合完成后展示：`✓ 已生成：docs/aolun.skill/<yyyy-mm-dd>-<brief>/99-final-<slug>.md`
```

- [ ] **Step 2：验证文件创建成功**

```bash
ls "skills/aolun-fileflow/"
```
预期输出：`SKILL.md`

- [ ] **Step 3：验证 frontmatter 合法性**

```bash
head -12 "skills/aolun-fileflow/SKILL.md"
```
预期输出：以 `---` 开始，包含 `name: aolun-fileflow` 和 `description:` 字段，以 `---` 结束。

- [ ] **Step 4：运行验证脚本**

```bash
npm test
```
预期：所有检查通过，包含 `aolun-fileflow` 的 frontmatter 验证。

- [ ] **Step 5：提交**

```bash
git add skills/aolun-fileflow/SKILL.md
git commit -m "feat: add aolun-fileflow skill for file-based persistent analysis"
```

---

### Task 3：验证完整流程并更新 AGENTS.md

**Files:**
- Modify: `AGENTS.md`（在 skill 列表中添加 `aolun-fileflow` 条目）

- [ ] **Step 1：在 AGENTS.md 的 skill 列表中添加 aolun-fileflow**

在 `AGENTS.md` 的 `| Path | Purpose |` 表格中已有的 skills 描述部分，找到对 `skills/` 的说明，在其后的叙述中补充 `aolun-fileflow` 的说明。

具体在 `## Repository structure` 部分的表格中，`skills/*/SKILL.md` 那行修改为：

```markdown
| `skills/*/SKILL.md` | Core skill definitions (16 skills). Each has YAML frontmatter (`name`, `description`) followed by markdown body. Names use `aolun-` prefix for entry skills and `aolun-inter-` prefix for internal pipeline skills. `aolun-fileflow` handles file-based persistent analysis for long texts (≥1500 chars). |
```

同时在 `## Skill dependency chain` 部分末尾添加：

```markdown
aolun-fileflow (文件持久化分析路由器，长文本 ≥1500字符时由 aolun-arming 自动路由) ⚡入口
  → 按序调用 aolun-dissect-concept → aolun-inter-dissect-mechanism →
    aolun-inter-dissect-constraint → aolun-inter-dissect-interest →
    aolun-scan-orchestrator → (可选) aolun-other-mountains → aolun-attack
  → 每步输出落盘为 docs/aolun.skill/<date>-<brief>/<NN>-<skill>.md
  → 用户确认后整合为 99-final-<slug>.md
```

- [ ] **Step 2：运行最终验证**

```bash
npm test
```
预期：全部通过。

- [ ] **Step 3：提交**

```bash
git add AGENTS.md
git commit -m "docs: document aolun-fileflow in AGENTS.md"
```
