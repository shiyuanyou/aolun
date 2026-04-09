---
name: aolun-workflows
description: |
  ⚡入口 skill。当你需要对一篇帖子执行完整的拆解攻击流程时调用；提供三条标准化工作流，定义 skill 的调用顺序、步骤间的数据传递和终止条件。
  English: Entry skill. Trigger when executing a full dissect-and-attack pipeline on a target post. Provides three standardized workflows with defined skill sequencing, data handoff, and termination conditions.
---

# 工作流编排层

> "打仗要有战法。随便乱冲，不叫勇敢，叫送死。"
> —— 李敖

方法的威力不在于单独使用某一件武器，而在于**在正确的时机以正确的顺序组合使用**。

---

## Workflow 1：快速狙击

**适用场景：** 看到一篇推文/短帖/论断，需要快速判断有没有真正的弱点，然后给一个有力的简短回应。

**时间预算：** 5-10 分钟

```
aolun-dissect-concept → aolun-scan-logic → aolun-attack（快速评论模式）
   概念解剖      →   逻辑扫描   →   输出50-200字攻击文
```

### 步骤详解

**Step 1：aolun-dissect-concept（概念层解剖）**
- 目标：30秒内找到最明显的概念问题
- 传递给 Step 2：
  ```
  核心声称：[一句话]
  最明显的概念问题：[一条]
  ```
- 终止条件：找到至少一个具体的概念漏洞

**Step 2：aolun-scan-logic（逻辑扫描）**
- 输入：Step 1 的概念问题
- 目标：找到推论中最致命的跳跃
- 传递给 Step 3：
  ```
  最致命的逻辑漏洞：[一条，附原文依据]
  ```
- 终止条件：找到一条可以一句话说清楚的逻辑失效

**Step 3：aolun-attack（快速评论模式）**
- 输入：Step 1 + Step 2 的结论
- 目标：写出一段50-200字的战斗文本
- 结构：复述主张 → 指出漏洞 → 一句定性
- 终止条件：文本可以直接发布

---

## Workflow 2：标准拆解

**适用场景：** 一篇值得认真对待的技术帖子或方案，需要全面拆解并写出有分量的评论文章。

**时间预算：** 30-60 分钟

```
aolun-dissect-concept → aolun-inter-dissect-mechanism → aolun-inter-dissect-constraint → aolun-inter-dissect-interest
     概念          →      机制           →       约束          →      利益
         ↓
aolun-scan-logic + aolun-scan-engineering + aolun-scan-history + aolun-scan-motive（并行）
   逻辑扫描  +    工程扫描         +   历史扫描     +   动机扫描
         ↓
   aolun-other-mountains（可选，如果有值得引入的跨领域解法）
         ↓
   aolun-attack（标准攻击文模式）
```

### 关键数据传递节点

**解剖层 → 扫描层：**
```
概念层结论：[定义问题 + 最关键的概念漏洞]
机制层结论：[因果链中最脆弱的环节]
约束层结论：[被隐藏的最关键约束 + 违反后果]
利益层结论：[主要利益方 + 信息选择偏差]
```

**扫描层 → 他山之石：**
```
工程弱点的结构本质：[抽象描述，去除领域专用词汇]
最需要解决的核心问题：[一句话]
```

**全部结论 → 攻击文：**
```
弱点清单（按攻击力排序）：
  1. [最致命的弱点]：[证据]
  2. [次致命弱点]：[证据]
  3. ...
跨领域解法（如有）：[来源 + 机制 + 迁移路径]
定性结论：[这个东西的真实定位]
```

---

## Workflow 3：底朝天全拆

**适用场景：** 对一个重要的技术方向或行业论断做彻底的长文拆解，输出深度技术评论。

**时间预算：** 1-3 小时

```
Phase 1：全层解剖（四个解剖器全部执行）
Phase 2：全维扫描（四个扫描器全部执行）
Phase 3：他山之石（寻找所有可用的跨领域解法）
Phase 4：综合攻击文（深度拆解结构）
```

### 各 Phase 的终止条件

**Phase 1 终止条件：**
四层解剖报告全部完成，且每层至少找到一个有具体依据的问题。

**Phase 2 终止条件：**
四个扫描器报告全部完成。弱点清单按照以下三个维度排序：
- 确定性（证据是否充分）
- 严重性（失效影响范围）
- 可攻击性（能否用一两句话说清楚）

**Phase 3 终止条件：**
找到至少一个结构相似性充分的跨领域解法，且迁移路径可以具体描述。

**Phase 4 终止条件：**
文章通过质量自检清单（见 aolun-attack 的质量自检部分）。

---

## 工作流选择指南

| 你的情况 | 推荐工作流 |
|---------|----------|
| 帖子不超过500字，需要快速回应 | Workflow 1：快速狙击 |
| 帖子是一篇完整的技术文章或方案 | Workflow 2：标准拆解 |
| 这是一个重要的行业论断或主流方法论 | Workflow 3：底朝天全拆 |
| 只需要找跨领域解法，不需要攻击文 | 四层解剖 + aolun-other-mountains |
| 只需要确认一个逻辑是否成立 | aolun-dissect-concept + aolun-scan-logic |
