# 并行扫描层重构设计

**日期：** 2026-04-13  
**状态：** 待实施  
**目标：** 引入 `aolun-scan-orchestrator` 将四个扫描器从串行改为并行 subagent 模式，降低主窗口上下文累积。

---

## 问题陈述

当前 aolun 的扫描层是串行的：

```
scan-logic → scan-engineering → scan-history → scan-motive
```

每个扫描器的完整报告都留在主窗口，到 `aolun-attack` 执行时，窗口已累积四份全文扫描报告。四个扫描器互相独立（逻辑/工程/历史/动机维度互不依赖），但现在没有利用这一点。

---

## 解决方案概览

新增一个 `aolun-scan-orchestrator` skill 作为并行 controller：

```
解剖层输出（四层摘要）
  ↓
aolun-scan-orchestrator
  ├── [并行] subagent: scan-logic       → 返回摘要块
  ├── [并行] subagent: scan-engineering → 返回摘要块
  ├── [并行] subagent: scan-history     → 返回摘要块
  └── [并行] subagent: scan-motive      → 返回摘要块
  ↓
汇总 → 扫描综合报告（单份，约 400 字）
  ↓
aolun-other-mountains / aolun-attack
```

主窗口的扫描层输出从「4×完整报告」缩减为「1×综合摘要」。

---

## 数据流规范

### Orchestrator 接收的输入

解剖层在移交给 orchestrator 之前，需压缩为以下格式（约 200 字）：

```
【解剖层输入摘要】
概念层：[核心声称] + [最关键的概念漏洞 1-2条]
机制层：[声称的原理] + [因果链中最脆弱的环节]
约束层：[被隐藏的关键约束] + [边界外失效场景]
利益层：[主要推动方] + [信息选择偏差方向]
```

### 每个 subagent 的输入

- 共享上下文：上述解剖层输入摘要（~200 字）
- 原始帖子文本
- 自身 skill 指令（只加载对应一个扫描器 skill）

不携带其他扫描器结果，不携带解剖层全文报告。

### 每个扫描器 skill 的新增输出块

在现有"向下游传递"节之后追加：

```
【致攻击层的摘要】
扫描器：[scan-logic / scan-engineering / scan-history / scan-motive]

弱点清单（按攻击力排序）：
  1. [弱点类型]：[原文证据，引号括起来] → 攻击力：[高/中/低]
  2. [弱点类型]：[原文证据] → 攻击力：[高/中/低]
  3. （最多5条）

最致命的一击：[一句话，这是整个维度下最不可辩护的漏洞]
```

### Orchestrator 的汇总输出

```
【扫描综合报告】
（由 aolun-scan-orchestrator 汇总，共4个维度）

逻辑维度最致命：[来自 scan-logic 的最致命一击]
工程维度最致命：[来自 scan-engineering 的最致命一击]
历史维度最致命：[来自 scan-history 的最致命一击]
动机维度最致命：[来自 scan-motive 的最致命一击]

全弱点清单（攻击力排序，去重合并）：
  1. [最高攻击力弱点] — [维度] — [证据]
  2. ...
  （最多10条）
```

---

## 文件改动清单

### 新增（1个文件）

| 文件 | 内容 |
|------|------|
| `skills/aolun-scan-orchestrator/SKILL.md` | 并行 controller skill：接收解剖摘要 → 单次消息 dispatch 四个并行 subagent → 汇总综合报告 |

### 修改（6个文件）

| 文件 | 改动 |
|------|------|
| `skills/aolun-scan-logic/SKILL.md` | 末尾追加 `【致攻击层的摘要】` 输出块模板 |
| `skills/aolun-scan-engineering/SKILL.md` | 同上 |
| `skills/aolun-scan-history/SKILL.md` | 同上 |
| `skills/aolun-scan-motive/SKILL.md` | 同上 |
| `skills/aolun-arming/SKILL.md` | 调度规则：四个 scan-* 行替换为 `→ aolun-scan-orchestrator`（并注明内部并行） |
| `skills/aolun-workflows/SKILL.md` | Workflow 2/3 扫描层改为 `aolun-scan-orchestrator（内部并行）`；更新数据传递节点格式 |

### 不改动

- `aolun-dissect-concept`、`aolun-inter-dissect-*`（解剖链串行依赖，架构不变）
- `aolun-attack`（只需能读综合报告，格式由 orchestrator 输出约束）
- `aolun-other-mountains`（接口不变）
- `.opencode/plugins/aolun.js`（不涉及）

---

## `aolun-scan-orchestrator` skill 核心逻辑草稿

```markdown
## 核心职责

接收解剖层输出摘要，以单次消息并行 dispatch 四个扫描器 subagent，
汇总返回结果为统一的扫描综合报告。

## 执行步骤

### Step 1：准备共享上下文
从解剖层结果中提炼「解剖层输入摘要」（约200字，格式见规范）。
原始帖子文本保持完整。

### Step 2：单次消息并行 dispatch
在同一条消息中发出四个 Task 工具调用：

Task 1 → scan-logic subagent
  输入：解剖层输入摘要 + 原始帖子 + scan-logic skill 指令
  要求：按摘要块格式输出，最多5条弱点

Task 2 → scan-engineering subagent
  （同上，skill 换为 scan-engineering）

Task 3 → scan-history subagent
  （同上，skill 换为 scan-history）

Task 4 → scan-motive subagent
  （同上，skill 换为 scan-motive）

### Step 3：汇总
四个 subagent 返回后：
1. 提取每份的「最致命的一击」→ 写入综合报告头部
2. 合并四份弱点清单 → 按攻击力重新排序 → 去重 → 取前10条
3. 输出「扫描综合报告」

## 向下游传递
综合报告传给 aolun-other-mountains 或 aolun-attack（视工作流决定）。
```

---

## 预期效果

| 指标 | 改造前 | 改造后 |
|------|--------|--------|
| 扫描层执行方式 | 串行，4次顺序调用 | 并行，1次 dispatch 4个 subagent |
| 扫描层在主窗口的输出体量 | 4×完整报告（约2000-4000字） | 1×综合摘要（约400字） |
| 各 subagent 的上下文 | 累积前所有步骤 | 仅解剖摘要 + 原文 + 自身 skill |
| 攻击文生成器的输入质量 | 需自行从4份报告提炼弱点 | 直接收到按攻击力排序的弱点清单 |

---

## 约束与边界

- 解剖层（concept → mechanism → constraint → interest）保持串行，不纳入本次改造范围
- `aolun-attack` 的 skill 内容不改，只依赖 orchestrator 输出格式的约束
- 新增的 `aolun-scan-orchestrator` 使用 `aolun-` 前缀（入口 skill，可直接调用）
- 所有 skill 保持双语（中文主体，英文 description）

---

## 验证方法

改动完成后运行现有验证脚本：

```bash
npm test
# 检查：所有 SKILL.md 有 frontmatter，JSON 有效，hooks 可执行
```

人工验证：
1. 用 Workflow 2 跑一篇技术帖子，确认四个扫描器 subagent 在单条消息中被 dispatch
2. 确认主窗口收到的是综合报告而非四份全文
3. 确认 `aolun-attack` 能从综合报告中正常生成攻击文
