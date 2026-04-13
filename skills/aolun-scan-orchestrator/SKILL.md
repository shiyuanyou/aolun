---
name: aolun-scan-orchestrator
description: |
  ⚡入口 skill。解剖层（四层）完成后调用。以单次消息并行 dispatch 四个扫描器 subagent（scan-logic / scan-engineering / scan-history / scan-motive），等待全部返回后汇总为一份扫描综合报告，传递给 aolun-other-mountains 或 aolun-attack。
  English: Entry skill. Trigger after all four dissection layers complete. Dispatches four scanner subagents in parallel (scan-logic / scan-engineering / scan-history / scan-motive) in a single message, then aggregates their structured summary blocks into one unified scan report for aolun-other-mountains or aolun-attack.
---

# 扫描层并行编排器

> "兵贵神速，更贵合围。四面同时出击，对手连逃跑的方向都找不到。"
> —— 李敖

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

> **平台注：** 在不支持 Task 并行调用的宿主中（如 Cursor、Codex），可改为依序执行四个扫描器，汇总方式相同，只是无法并行加速。

**Task 1 → scan-logic subagent**
```
你是一个逻辑弱点扫描器。使用 aolun-scan-logic skill。

【输入】
解剖层摘要：
[粘贴解剖层输入摘要]

原始帖子：
[粘贴完整原文]

【要求】
执行 aolun-scan-logic 的完整扫描流程，然后在报告末尾追加以下摘要块：

【致攻击层的摘要】（来自 scan-logic）
最致命的一击：[一句话，整个逻辑维度下最不可辩护的推论漏洞]
弱点清单（最多5条，按攻击力排序）：
  1. [谬误类型] — [原文证据，用引号] — 攻击力：[高/中/低]
  2. ...
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
执行 aolun-scan-engineering 的完整扫描流程，然后在报告末尾追加以下摘要块：

【致攻击层的摘要】（来自 scan-engineering）
最致命的一击：[一句话，真实生产环境下最可能导致方案失败的单点问题]
弱点清单（最多5条，按攻击力排序）：
  1. [弱点类型] — [原文证据，用引号] — 攻击力：[高/中/低]
  2. ...
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
执行 aolun-scan-history 的完整扫描流程，然后在报告末尾追加以下摘要块：

【致攻击层的摘要】（来自 scan-history）
最致命的一击：[一句话，最能说明这个"新东西"本质是旧问题的历史证据]
弱点清单（最多5条，按攻击力排序）：
  1. [历史原型] — [原文证据，用引号] — 攻击力：[高/中/低]
  2. ...
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
执行 aolun-scan-motive 的完整扫描流程，然后在报告末尾追加以下摘要块：

【致攻击层的摘要】（来自 scan-motive）
最致命的一击：[一句话，这篇帖子最根本的动机如何决定性地影响了结论]
弱点清单（最多5条，按攻击力排序）：
  1. [动机扭曲类型] — [原文证据，用引号] — 攻击力：[高/中/低]
  2. ...
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
