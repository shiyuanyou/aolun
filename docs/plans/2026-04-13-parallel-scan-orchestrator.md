# Parallel Scan Orchestrator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `aolun-scan-orchestrator` skill，将四个扫描器从串行改为并行 subagent 模式，同时在四个扫描器末尾追加结构化摘要块，降低主窗口上下文累积。

**Architecture:** 新增一个 orchestrator skill 作为并行 controller，接收解剖层输入摘要后在单次消息中 dispatch 四个扫描器 subagent，各 subagent 只携带最小上下文（解剖摘要 + 原文 + 自身 skill），返回固定格式摘要块，orchestrator 汇总为一份综合报告传给攻击层。

**Tech Stack:** Markdown skill 文件（无可执行代码），YAML frontmatter，`npm test` 验证脚本（`bash tests/validate.sh`）

---

## File Structure

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `skills/aolun-scan-orchestrator/SKILL.md` | 并行 controller：dispatch 四个 subagent，汇总综合报告 |
| 修改 | `skills/aolun-scan-logic/SKILL.md` | 末尾追加 `【致攻击层的摘要】` 输出块模板 |
| 修改 | `skills/aolun-scan-engineering/SKILL.md` | 同上 |
| 修改 | `skills/aolun-scan-history/SKILL.md` | 同上 |
| 修改 | `skills/aolun-scan-motive/SKILL.md` | 同上 |
| 修改 | `skills/aolun-arming/SKILL.md` | 调度规则中四个 scan-* 替换为 aolun-scan-orchestrator |
| 修改 | `skills/aolun-workflows/SKILL.md` | Workflow 2/3 扫描层及数据传递节点更新 |

---

## Task 1：新建 `aolun-scan-orchestrator` skill

**Files:**
- Create: `skills/aolun-scan-orchestrator/SKILL.md`

- [ ] **Step 1：创建目录**

```bash
mkdir -p skills/aolun-scan-orchestrator
```

- [ ] **Step 2：写入 SKILL.md**

创建文件 `skills/aolun-scan-orchestrator/SKILL.md`，内容如下：

```markdown
---
name: aolun-scan-orchestrator
description: |
  ⚡入口 skill。解剖层（四层）完成后调用。以单次消息并行 dispatch 四个扫描器 subagent（scan-logic / scan-engineering / scan-history / scan-motive），等待全部返回后汇总为一份扫描综合报告，传递给 aolun-other-mountains 或 aolun-attack。
  English: Entry skill. Trigger after all four dissection layers complete. Dispatches four scanner subagents in parallel (scan-logic / scan-engineering / scan-history / scan-motive) in a single message, then aggregates their structured summary blocks into one unified scan report for aolun-other-mountains or aolun-attack.
---

# 扫描层并行编排器

> "兵贵神速，更贵合围。四面同时出击，对手连逃跑的方向都找不到。"

## 核心职责

接收解剖层输出摘要，以**单次消息**并行 dispatch 四个扫描器 subagent，汇总返回结果为统一的扫描综合报告。

**关键约束：**
- 四个 subagent 必须在同一条消息中发出（真正并行）
- 每个 subagent 只携带最小上下文（解剖摘要 + 原文），不携带解剖层全文
- 综合报告是唯一传递给下游的内容，四份 subagent 全文报告不进入主窗口

---

## 执行步骤

### Step 1：准备解剖层输入摘要

从解剖层四份报告中提炼以下格式（约 200 字）：

```
【解剖层输入摘要】
概念层：[核心声称] + [最关键的概念漏洞 1-2条]
机制层：[声称的原理] + [因果链中最脆弱的环节]
约束层：[被隐藏的关键约束] + [边界外失效场景]
利益层：[主要推动方] + [信息选择偏差方向]
```

### Step 2：单次消息并行 dispatch 四个 subagent

**在同一条消息中发出四个 Task 工具调用**（不得分开发送）：

**Task 1 → scan-logic subagent**
```
你是一个逻辑弱点扫描器。使用 aolun-scan-logic skill。

【输入】
解剖层摘要：
[粘贴解剖层输入摘要]

原始帖子：
[粘贴完整原文]

【要求】
执行 aolun-scan-logic 的完整扫描流程，然后在报告末尾输出标准的
【致攻击层的摘要】块（格式见 skill 末尾模板）。最多5条弱点。
```

**Task 2 → scan-engineering subagent**
```
你是一个工程弱点扫描器。使用 aolun-scan-engineering skill。

【输入】
解剖层摘要：
[粘贴解剖层输入摘要]

原始帖子：
[粘贴完整原文]

【要求】
执行 aolun-scan-engineering 的完整扫描流程，然后在报告末尾输出标准的
【致攻击层的摘要】块（格式见 skill 末尾模板）。最多5条弱点。
```

**Task 3 → scan-history subagent**
```
你是一个历史弱点扫描器。使用 aolun-scan-history skill。

【输入】
解剖层摘要：
[粘贴解剖层输入摘要]

原始帖子：
[粘贴完整原文]

【要求】
执行 aolun-scan-history 的完整扫描流程，然后在报告末尾输出标准的
【致攻击层的摘要】块（格式见 skill 末尾模板）。最多5条弱点。
```

**Task 4 → scan-motive subagent**
```
你是一个动机弱点扫描器。使用 aolun-scan-motive skill。

【输入】
解剖层摘要：
[粘贴解剖层输入摘要]

原始帖子：
[粘贴完整原文]

【要求】
执行 aolun-scan-motive 的完整扫描流程，然后在报告末尾输出标准的
【致攻击层的摘要】块（格式见 skill 末尾模板）。最多5条弱点。
```

### Step 3：汇总综合报告

四个 subagent 全部返回后，从每份报告中提取 `【致攻击层的摘要】` 块，汇总为：

```
【扫描综合报告】
（由 aolun-scan-orchestrator 汇总，共4个维度）

逻辑维度最致命：[来自 scan-logic 的"最致命的一击"]
工程维度最致命：[来自 scan-engineering 的"最致命的一击"]
历史维度最致命：[来自 scan-history 的"最致命的一击"]
动机维度最致命：[来自 scan-motive 的"最致命的一击"]

全弱点清单（攻击力排序，去重合并，最多10条）：
  1. [弱点类型] — [维度] — [原文证据] — 攻击力：[高/中/低]
  2. [弱点类型] — [维度] — [原文证据] — 攻击力：[高/中/低]
  3. ...
```

**汇总规则：**
- 按攻击力（高→中→低）排序
- 同一证据被多个扫描器引用时合并为一条，注明多维度
- 超过10条时保留攻击力最高的10条

---

## 向下游传递

综合报告传给：
- `aolun-other-mountains`：工程弱点清单作为跨领域解法的需求入口
- `aolun-attack`：完整综合报告作为攻击文弹药库
```

- [ ] **Step 3：运行验证**

```bash
npm test
```

预期输出：所有检查通过，无 `SKILL.md frontmatter missing` 错误。

- [ ] **Step 4：提交**

```bash
git add skills/aolun-scan-orchestrator/SKILL.md
git commit -m "feat: add aolun-scan-orchestrator parallel controller skill"
```

---

## Task 2：在四个扫描器末尾追加摘要块

**Files:**
- Modify: `skills/aolun-scan-logic/SKILL.md`
- Modify: `skills/aolun-scan-engineering/SKILL.md`
- Modify: `skills/aolun-scan-history/SKILL.md`
- Modify: `skills/aolun-scan-motive/SKILL.md`

追加的内容对四个文件相同（只有"扫描器："字段填对应名称），追加位置：现有文件末尾（`## 向下游传递` 节之后）。

- [ ] **Step 1：修改 `aolun-scan-logic/SKILL.md`**

在文件末尾追加：

```markdown

---

## 摘要输出规范（供 aolun-scan-orchestrator 使用）

当作为 subagent 被 orchestrator 调用时，在完整报告末尾追加以下格式块：

```
【致攻击层的摘要】
扫描器：scan-logic

弱点清单（按攻击力排序，最多5条）：
  1. [谬误类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  2. [谬误类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  3. ...

最致命的一击：[一句话，整个逻辑维度下最不可辩护的推论漏洞]
```
```

- [ ] **Step 2：修改 `aolun-scan-engineering/SKILL.md`**

在文件末尾追加：

```markdown

---

## 摘要输出规范（供 aolun-scan-orchestrator 使用）

当作为 subagent 被 orchestrator 调用时，在完整报告末尾追加以下格式块：

```
【致攻击层的摘要】
扫描器：scan-engineering

弱点清单（按攻击力排序，最多5条）：
  1. [弱点类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  2. [弱点类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  3. ...

最致命的一击：[一句话，真实生产环境下最可能导致方案失败的单点问题]
```
```

- [ ] **Step 3：修改 `aolun-scan-history/SKILL.md`**

在文件末尾追加：

```markdown

---

## 摘要输出规范（供 aolun-scan-orchestrator 使用）

当作为 subagent 被 orchestrator 调用时，在完整报告末尾追加以下格式块：

```
【致攻击层的摘要】
扫描器：scan-history

弱点清单（按攻击力排序，最多5条）：
  1. [历史原型]：[原文引用，用引号] → 攻击力：[高/中/低]
  2. [历史原型]：[原文引用，用引号] → 攻击力：[高/中/低]
  3. ...

最致命的一击：[一句话，最能说明这个"新东西"本质是旧问题的历史证据]
```
```

- [ ] **Step 4：修改 `aolun-scan-motive/SKILL.md`**

在文件末尾追加：

```markdown

---

## 摘要输出规范（供 aolun-scan-orchestrator 使用）

当作为 subagent 被 orchestrator 调用时，在完整报告末尾追加以下格式块：

```
【致攻击层的摘要】
扫描器：scan-motive

弱点清单（按攻击力排序，最多5条）：
  1. [动机扭曲类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  2. [动机扭曲类型]：[原文引用，用引号] → 攻击力：[高/中/低]
  3. ...

最致命的一击：[一句话，这篇帖子最根本的动机如何决定性地影响了结论]
```
```

- [ ] **Step 5：运行验证**

```bash
npm test
```

预期输出：所有检查通过。

- [ ] **Step 6：提交**

```bash
git add skills/aolun-scan-logic/SKILL.md skills/aolun-scan-engineering/SKILL.md skills/aolun-scan-history/SKILL.md skills/aolun-scan-motive/SKILL.md
git commit -m "feat: add structured summary block to all four scanner skills"
```

---

## Task 3：更新 `aolun-arming` 调度规则

**Files:**
- Modify: `skills/aolun-arming/SKILL.md`

- [ ] **Step 1：替换调度规则中的扫描器列表**

找到以下内容（`skills/aolun-arming/SKILL.md` 第 63-75 行）：

```markdown
    → aolun-scan-logic       逻辑弱点扫描  ⚡入口
    → aolun-scan-engineering 工程弱点扫描  ⚡入口
    → aolun-scan-history     历史弱点扫描  ⚡入口
    → aolun-scan-motive      动机弱点扫描  ⚡入口
```

替换为：

```markdown
    → aolun-scan-orchestrator  并行扫描编排器（内部并行 dispatch 四个扫描器）⚡入口
```

- [ ] **Step 2：更新调度说明表**

找到：

```markdown
| 写一篇有力的技术评论 | 四层解剖 + 全部扫描器 + aolun-attack |
```

替换为：

```markdown
| 写一篇有力的技术评论 | 四层解剖 + aolun-scan-orchestrator + aolun-attack |
```

- [ ] **Step 3：更新 Skill 命名规范表**

找到入口 Skill 表中以下四行：

```markdown
| `aolun-scan-logic` | 逻辑弱点扫描 |
| `aolun-scan-engineering` | 工程弱点扫描 |
| `aolun-scan-history` | 历史弱点扫描 |
| `aolun-scan-motive` | 动机弱点扫描 |
```

替换为：

```markdown
| `aolun-scan-orchestrator` | 并行扫描编排器（内部 dispatch 四个扫描器） |
| `aolun-scan-logic` | 逻辑弱点扫描（可单独调用，也可由 orchestrator 调用） |
| `aolun-scan-engineering` | 工程弱点扫描（可单独调用，也可由 orchestrator 调用） |
| `aolun-scan-history` | 历史弱点扫描（可单独调用，也可由 orchestrator 调用） |
| `aolun-scan-motive` | 动机弱点扫描（可单独调用，也可由 orchestrator 调用） |
```

- [ ] **Step 4：运行验证**

```bash
npm test
```

预期输出：所有检查通过。

- [ ] **Step 5：提交**

```bash
git add skills/aolun-arming/SKILL.md
git commit -m "feat: update aolun-arming routing to use scan-orchestrator"
```

---

## Task 4：更新 `aolun-workflows` 工作流描述

**Files:**
- Modify: `skills/aolun-workflows/SKILL.md`

- [ ] **Step 1：更新 Workflow 2 扫描层**

找到（第 65-66 行）：

```markdown
aolun-scan-logic + aolun-scan-engineering + aolun-scan-history + aolun-scan-motive（并行）
   逻辑扫描  +    工程扫描         +   历史扫描     +   动机扫描
```

替换为：

```markdown
aolun-scan-orchestrator（单次消息并行 dispatch 四个扫描器 subagent）
   → 返回扫描综合报告（约400字，替代原四份全文报告）
```

- [ ] **Step 2：更新 Workflow 2 数据传递节点**

找到（第 84-87 行）：

```markdown
**扫描层 → 他山之石：**
```
工程弱点的结构本质：[抽象描述，去除领域专用词汇]
最需要解决的核心问题：[一句话]
```
```

替换为：

```markdown
**扫描层 → 他山之石：**
```
（从扫描综合报告中提取）
工程维度最致命：[来自综合报告的工程维度最致命一击]
最需要解决的核心问题：[综合四个维度后的一句话定性]
```
```

- [ ] **Step 3：更新 Workflow 2 全部结论传递格式**

找到（第 90-98 行）：

```markdown
**全部结论 → 攻击文：**
```
弱点清单（按攻击力排序）：
  1. [最致命的弱点]：[证据]
  2. [次致命弱点]：[证据]
  3. ...
跨领域解法（如有）：[来源 + 机制 + 迁移路径]
定性结论：[这个东西的真实定位]
```
```

替换为：

```markdown
**全部结论 → 攻击文：**
```
（直接使用 aolun-scan-orchestrator 输出的扫描综合报告）

扫描综合报告包含：
  - 四个维度各自的最致命一击
  - 全弱点清单（攻击力排序，去重合并，最多10条）
跨领域解法（如有）：[来源 + 机制 + 迁移路径]
定性结论：[这个东西的真实定位]
```
```

- [ ] **Step 4：更新 Workflow 3 Phase 2 描述**

找到（第 113-114 行）：

```markdown
Phase 2：全维扫描（四个扫描器全部执行）
```

替换为：

```markdown
Phase 2：全维扫描（调用 aolun-scan-orchestrator，内部并行执行四个扫描器）
```

- [ ] **Step 5：运行验证**

```bash
npm test
```

预期输出：所有检查通过。

- [ ] **Step 6：提交**

```bash
git add skills/aolun-workflows/SKILL.md
git commit -m "feat: update aolun-workflows to use scan-orchestrator for parallel scanning"
```

---

## Task 5：最终集成验证

**Files:** 无新修改

- [ ] **Step 1：运行完整验证**

```bash
npm test
```

预期输出：
```
✓ JSON files valid
✓ Required files present
✓ SKILL.md frontmatter present (13 skills)
✓ Command frontmatter present
✓ hooks/session-start executable
All checks passed.
```

- [ ] **Step 2：人工检查 orchestrator skill 在 AGENTS.md skill 表中是否需要更新**

检查 `AGENTS.md` 中是否有 skill 列表，如有则在入口 skill 表中添加 `aolun-scan-orchestrator`。

- [ ] **Step 3：提交最终收尾**

```bash
git add -A
git status
# 确认只有预期内的变更
git commit -m "chore: final integration check for parallel scan orchestrator"
```

（若 Step 2 无改动则跳过此步）
