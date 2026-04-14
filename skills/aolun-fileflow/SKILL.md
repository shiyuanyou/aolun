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
> —— 毛泽东《论持久战》

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

如果 `docs/aolun.skill/` 目录不存在，先创建它。

然后创建任务子目录：
```
docs/aolun.skill/<yyyy-mm-dd>-<brief>/
```

使用当天日期（格式：`2026-04-14`）。

### 3. 询问工作流

展示以下选择，等待用户回复：

```
即将开始文件持久化分析。请选择工作流：

[1] Workflow 1 快速狙击（仅落盘）
    概念解剖 → 逻辑扫描 → 攻击文（50-200字）
    适合：只需要快速定位主要弱点，不做全面拆解

[2] Workflow 2 标准拆解（推荐）
    四层解剖 → 并行扫描 → 可选他山之石 → 攻击文
    适合：一篇完整的技术文章或方案

[3] Workflow 3 底朝天全拆
    同上，但扫描后增加深度验证轮次
    适合：重要行业论断或主流方法论

任务目录已创建：docs/aolun.skill/{date}-{brief}/
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
   [修改] 对当前已完成步骤（<NN>-<skill-name>）提出修改意见，重新执行并覆盖写入
   [跳过] 跳过下一步
   [结束] 在此停止

⑥ 等待用户回复后再继续
```

**修改时：** 重新执行当前 skill（将用户修改意见作为附加指令传入），覆盖写入文件，再次展示摘要，再次暂停询问。

**跳过时：** 在下一个文件的头部注释中记录：`> 注：<NN>-<skill-name> 已跳过`，继续执行再下一步。

---

## Part 3：步骤序列定义

### Workflow 1：快速狙击（落盘版）

| 步骤文件 | 调用 Skill | 是否必须 |
|---------|-----------|---------|
| `01-dissect-concept.md` | `aolun-dissect-concept` | 必须 |
| `02-scan-logic.md` | `aolun-scan-logic` | 必须 |
| `03-attack.md` | `aolun-attack`（快速评论模式，50-200字） | 必须 |
| `99-final-<slug>.md` | — | 用户选择整合时生成 |

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

> **注（`05-scan-summary.md` 特殊处理）：** `aolun-scan-orchestrator` 内部会并行 dispatch 四个扫描子 agent。fileflow 将其最终输出的 `【扫描综合报告】` 块写入 `05-scan-summary.md`，各扫描子 agent 的全文报告不单独落盘。

### Workflow 3：底朝天全拆

同 Workflow 2，在 `05-scan-summary.md` 之后增加：

| 步骤文件 | 调用 Skill | 说明 |
|---------|-----------|------|
| `05b-scan-logic-deep.md` | `aolun-scan-logic` | 对逻辑漏洞证据不足条目补充深度调查 |
| `05c-scan-engineering-deep.md` | `aolun-scan-engineering` | 对工程弱点证据不足条目补充深度调查 |

---

## Part 4：文件格式规范

### 中间态文件格式

每个编号文件的内容格式：

```
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

```
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

---

## 向下游传递

fileflow 完成整合后，输出：

- `99-final-<slug>.md` 的完整文件路径
- 可将此路径传递给任意下游 skill 作为完整分析文档使用

如需继续对分析结果做后处理（如生成发布稿），将 `99-final-<slug>.md` 路径作为输入传入对应 skill 即可。
