---
name: aolun-fileflow
description: |
  ⚡入口 skill。当分析文本字符数 ≥ 1500 时由 aolun-arming 自动路由，或用户直接调用。
  基于文件持久化的逐步分析路由器：主 agent 只管状态和调度，所有文本分析由 subagent 在文件系统中完成。
  00-todolist.md 是唯一的真相源。防止长文本分析中的 compact 上下文丢失。
  English: Entry skill. Auto-routed from aolun-arming when input ≥ 1500 chars, or invoked directly.
  File-based persistent analysis router: the main agent only manages state and dispatch; all text analysis
  is done by subagents reading files directly. 00-todolist.md is the single source of truth.
  Prevents context loss from compaction on long texts.
---

# 文件持久化分析路由器

> "打持久战，要有根据地。"
> —— 毛泽东《论持久战》

长文本分析是持久战。没有根据地（文件落盘），中间态就会在 compact 中消失。

本 skill 的核心原则：

**主 agent 只做两件事：管 `00-todolist.md`、派发 subagent。**
**所有文本分析由 subagent 完成——subagent 自己从文件系统读原文、读上游输出。**
**主 agent 永远不把原文内容或上游输出内容塞进 prompt——只传文件路径。**

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

### 2. 检测已有文档准备结果

如果任务目录已存在且其中有 `00-prep-meta.md`：

1. 读取 `00-prep-meta.md` 的输入形态和存储模式
2. 向用户展示：`检测到已有的文档准备结果（<输入形态>，<存储模式>，<准备时间>）。`
3. 跳过文档准备步骤，直接进入创建 `00-todolist.md`（格式见 Part 4，从 `00-prep-meta.md` 读取搜索策略）
4. 继续执行崩溃恢复检测

如果没有 `00-prep-meta.md`，继续执行文档准备逻辑。

### 3. 创建任务目录和文档准备

如果 `docs/aolun.skill/` 目录不存在，先创建它。

创建任务子目录：
```
docs/aolun.skill/<yyyy-mm-dd>-<brief>/
```

**内联简化文档准备（仅支持粘贴文本场景）：**

将原始输入文本保存为 `00-original.md`（纯原文，无 header 注释，第 1 行就是原文第 1 行）。

如果输入是文件路径或目录路径（而非粘贴文本），且 `00-prep-meta.md` 不存在：
```
提示用户："检测到路径输入但未找到文档准备结果。请先使用 aolun-prepare-docs 准备文档，或直接粘贴文本。"
终止当前流程。
```

创建根据地文件 `00-todolist.md`（格式见 Part 4）。如果 `00-prep-meta.md` 存在，从其搜索策略部分读取并填充 00-todolist.md 的搜索策略；否则使用默认搜索策略。

### 4. 崩溃恢复检测

如果 `docs/aolun.skill/<yyyy-mm-dd>-<brief>/00-todolist.md` 已存在：

1. 读取状态表
2. 找到第一个状态为 `⬜待执行` 的步骤
3. 告知用户：`检测到未完成的任务，从步骤 <NN>-<skill-name> 继续执行。是否继续？[继续] [从头开始]`
4. 继续 → 从该步骤恢复执行
5. 从头开始 → 清空任务目录后重建

### 5. 询问工作流

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

任务目录已创建：docs/aolun.skill/<yyyy-mm-dd>-<brief>/
```

### 6. 展示执行计划

根据用户选择，展示步骤序列（见 Part 3），等待用户确认开始。

---

## Part 2：逐步执行规则

### 核心架构

```
主 agent（fileflow 编排器）
  ├── 管理唯一真相源：00-todolist.md
  ├── 派发 subagent（只传文件路径，不传文本内容）
  ├── 从输出文件提取【摘要】块展示给用户
  └── 等待用户确认，更新状态表

subagent（每个分析步骤）
  ├── 自己用 Read/Grep 工具读原始文件
  ├── 自己用 Read 工具读上游输出文件（按需）
  ├── 自己用 Read 工具读 00-todolist.md 获取索引和搜索策略
  ├── 执行 skill 分析
  └── 将完整输出写入指定文件路径
```

**禁止：** 主 agent 将原文段落、上游输出内容复制进 subagent prompt。

**允许：** 主 agent 将文件路径、搜索策略、任务指令写进 subagent prompt。

### 每步执行流程

```
① 更新 00-todolist.md 状态表：当前步骤标记为 🔄当前

② 派发 subagent，prompt 模板：

你是 aolun 分析管线的一环。执行 <skill-name> 分析。

    【文件路径】（根据输入模式选择以下分支之一，主 agent 将 <...> 替换为实际值）

    分支 A（粘贴模式/单文件快照/单文件引用）：
    - 原始文件：<00-original.md 的完整路径>（粘贴/快照）或 <源文件绝对路径>（引用）
    - 索引与状态：<00-todolist.md 的完整路径>
    - 上游输出：<上一步输出文件的完整路径>（第一步无此项）

    分支 B（目录快照）：
    - 源目录：<任务目录>/00-sources/
    - 索引入口：<任务目录>/00-index.md
    - 索引与状态：<00-todolist.md 的完整路径>
    - 上游输出：<任务目录>/<上一步文件名>（第一步无此项）

    分支 C（目录引用）：
    - 源目录：<源目录绝对路径>
    - 索引入口：<任务目录>/00-index.md
    - 索引与状态：<00-todolist.md 的完整路径>
    - 上游输出：<任务目录>/<上一步文件名>（第一步无此项）

    主 agent 在派发 subagent 前必须根据 00-todolist.md 或 00-prep-meta.md 中的输入模式选择对应分支。

   【执行指令】
   1. 先读 00-todolist.md 中的"原文索引"和"搜索策略"部分，获取搜索线索
   2. 使用 Read 和 Grep 工具直接搜索原始文件，找到关键证据
      - 搜索核心概念在不同章节的定义，寻找内部矛盾
      - 搜索所有数字声称，验证引用来源
      - 搜索关键词汇的歧义用法
      - 每个弱点必须附有原文行号和直接引用
   3. 如需参考上游分析结论，Read 上游输出文件
   4. 按照 <skill-name> 的 SKILL.md 指令执行完整分析
   5. 将完整输出写入：<当前步骤输出文件的完整路径>

   【输出格式】
   文件顶部必须包含【摘要】块（3-5行，给出本步骤的核心判断），
   然后是 --- 分隔线，然后是完整分析内容。格式见 00-todolist.md 中的引用说明。

③ 等待 subagent 完成

④ 从输出文件提取【摘要】块（3-5行）

⑤ 更新 00-todolist.md：
   - 状态表：当前步骤标记为 ✅完成
   - 摘要列：写入提取的摘要

⑥ 如果是 01-dissect-concept 步骤，额外操作：
   读 01 输出文件，提取概念层发现的关键位置信息，
   追加到 00-todolist.md 的"语义线索"部分

⑦ 在对话中展示摘要（不展示全文）

⑧ 暂停，显示操作提示：

   ✓ 已保存：<文件名>
   摘要：<提取的摘要1-2行>

   下一步：<NN+1>-<skill-name>
   [继续] 执行下一步
   [修改] 对当前已完成步骤提出修改意见，重新执行并覆盖写入
   [跳过] 跳过下一步
   [结束] 在此停止

⑨ 等待用户回复后再继续
```

**修改时：** 重新派发 subagent（将用户修改意见作为附加指令传入），覆盖写入文件，再次展示摘要，再次暂停。

**跳过时：** 在 00-todolist.md 状态表中标记为 ⊘跳过，在下一个输出文件头部注释中记录 `> 注：<NN>-<skill-name> 已跳过`，继续执行下一步。

### 01-dissect-concept 特殊处理

概念层解剖是唯一需要建立全局理解的步骤。派发 prompt 中追加：

```
【概念层特别指令】
这是第一步分析，你需要建立对文章的全局理解。
请使用 Read 工具完整阅读原始文件（可分段读取）。
概念层的目标是回答"这东西声称自己是什么"——必须看全貌。
完成分析后，在 00-todolist.md 的"语义线索"部分追加你发现的关键位置索引。
```

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

### 00-todolist.md 格式

```markdown
# 任务根据地 — <brief>

> 创建时间：<yyyy-mm-dd HH:MM>
> 工作流：<Workflow 1/2/3>

---

## 执行状态

| 步骤 | 状态 | 输出文件 | 摘要 |
|------|------|---------|------|
| 01-dissect-concept | ⬜待执行 | 01-dissect-concept.md | — |
| 02-dissect-mechanism | ⬜待执行 | 02-dissect-mechanism.md | — |
| 03-dissect-constraint | ⬜待执行 | 03-dissect-constraint.md | — |
| 04-dissect-interest | ⬜待执行 | 04-dissect-interest.md | — |
| 05-scan-summary | ⬜待执行 | 05-scan-summary.md | — |
| 06-other-mountains | ⬜待执行 | 06-other-mountains.md | — |
| 07-attack | ⬜待执行 | 07-attack.md | — |

> 状态标记：⬜待执行 🔄当前 ✅完成 ⊘跳过

---

## 原文索引

- 输入模式：[粘贴 / 单文件快照 / 单文件引用 / 目录快照 / 目录引用]
- 存储模式：[快照 / 引用]
- 源路径：<绝对路径>（引用模式时有值；快照模式时可为空或记录原始路径用于溯源）
- 单文件路径：<00-original.md 的绝对路径>（粘贴/单文件快照时有值）
- 或引用源文件：<源文件绝对路径>（单文件引用时有值）
- 源目录路径：<00-sources/ 的绝对路径>（目录快照时有值）
- 或引用源目录：<源目录的绝对路径>（目录引用时有值）
- 索引入口：<00-index.md 的绝对路径>（目录模式时有值）
- 外部索引：<用户提供的 index 路径>（用户提供时有值，否则为"无"）
- 总行数：<自动统计>

### 结构索引（自动扫描）

<根据原文件格式自动提取：>
- 章节标题：搜索 "^#+ "，记录行号和标题文本
- 数学公式块：搜索 "$$" 或 "\\["，记录行号范围
- 表格：搜索 "^|" 或 "表\\d" 或 "Table"，记录行号范围
- 图表标题：搜索 "图\\d" 或 "Figure"，记录行号范围
- 代码块：搜索 "```"，记录行号范围

### 语义线索（01-dissect-concept 后追加）

<概念层解剖完成后，由 01 的 subagent 在此补充关键位置索引>
<包括：核心声称所在行号、疑似概念偷换位置、关键论证链起点等>
<单文件模式使用 第<N>行 格式，目录模式使用 <文件名>:<N> 格式>

---

## 搜索策略

<如果 00-prep-meta.md 存在，从其搜索策略部分读取填充。否则使用以下默认策略：>

- 核心声称定位：搜索 "提出"、"认为"、"表明"、"证明"
- 数据和证据定位：搜索数字模式、百分比、引用来源
- 定义关键术语：搜索 "所谓"、"定义为"、"是指"

<01-dissect-concept 完成后，语义线索可能更新搜索策略>
```

### 00-original.md 格式

纯原文，无 header 注释，第 1 行就是原文第 1 行。

溯源信息（源路径、模式、时间戳）不记录在 00-original.md 中，而是记录在 00-prep-meta.md 或 00-todolist.md 的原文索引中。

### 中间态文件格式

每个编号文件的内容格式：

```markdown
# <skill名称> — <任务brief>

> 执行时间：<yyyy-mm-dd HH:MM>
> 输入来源：00-original.md / <上一步文件名>
> 状态：完成 / 已修改（第N次）

---

【摘要】
<3-5行，给出本步骤的核心判断。下游步骤先读此摘要，需要深挖再搜全文。>

---

<skill 完整输出>
```

### 摘要提取规则

从输出文件中提取 `【摘要】` 块的 3-5 行内容。

如果文件中没有 `【摘要】` 块，则提取最后一个以 `【` 开头的块内最后一个非空行。

如果两种都找不到，提取文件最后5行中第一个非空行。

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

> 从 00-todolist.md 状态表的摘要列和各步骤【摘要】块中提取：

- **概念层**：<01 摘要>
- **机制层**：<02 摘要>
- **约束层**：<03 摘要>
- **利益层**：<04 摘要>
- **扫描综合**：<05 摘要>
- **攻击文定性**：<07 摘要>
```

整合完成后展示：`✓ 已生成：docs/aolun.skill/<yyyy-mm-dd>-<brief>/99-final-<slug>.md`

---

## 向下游传递

fileflow 完成整合后，输出：

- `99-final-<slug>.md` 的完整文件路径
- 可将此路径传递给任意下游 skill 作为完整分析文档使用

如需继续对分析结果做后处理（如生成发布稿），将 `99-final-<slug>.md` 路径作为输入传入对应 skill 即可。