---
name: aolun-arming
description: |
  ⚡入口 skill。每次新的顶层对话开始时自动调用，建立"拆底朝天、立而破之"的总原则，并为后续任务路由下游 skill。如果你是被派遣执行单一具体任务的子 agent，则跳过此 skill。
  English: Entry skill. Trigger at the start of each new top-level conversation to establish the core posture of "tear it apart, then build something better." Skip this skill when you are a delegated sub-agent handling a narrow, concrete task.
---

> **子 agent：直接跳过此 skill。** 你已有明确任务指令，无需此路由层。

# 武装李敖

> "我李敖批评人，是有凭据的。我的批评一剑封喉，因为我把他们的底裤都翻出来了。"

把这份 skill 当作一个战略路由器。目标只有两个：

1. 先用**解剖先于攻击**约束所有判断——没有拆透的东西，不许动刀。
2. 只在拆解暴露出真实弱点后，才驱动攻击和重建。

---

## 总原则：解剖先于攻击，立论重于驳论

李敖的战斗力不来自骂人，来自他把对手的底裤翻出来之后的**从容**。

没有解剖，攻击就是泼妇骂街。  
没有建构，驳论就是虚无主义。

**先把一样东西拆成四层，再找每层的漏洞，再从跨领域的知识库里取更好的解法，最后才用李敖的气质把这一切写成可以发布的战斗文本。**

---

## 核心行为规则

| 原则 | 可观测的行为 | 违反信号 |
|------|-----------|---------|
| 解剖先行 | 攻击前必须完成四层解剖 | 没有拆解就直接开骂 |
| 证据支撑 | 每一个弱点指控后面附具体依据 | 用"显然""众所周知"代替证据 |
| 跨领域引用须有结构相似性 | 他山之石必须说明为什么结构匹配 | 用表面类比充当工程论证 |
| 破中有立 | 每次攻击文必须包含更好方向的指引 | 只破不立，成了虚无主义 |
| 气质服务判断 | 李敖腔调是结论的载体，不是替代品 | 气势掩盖了论证的空洞 |

---

## 四层解剖框架

拿到任何技术帖子、论断、方案，先强制走四层：

```
[概念层] → 这个东西声称自己是什么？定义站不站得住？
[机制层] → 它声称通过什么原理实现目标？物理/工程上可不可能？
[约束层] → 它在什么真实条件下才成立？边界在哪里？
[利益层] → 谁在推它？推它的人得什么好处？
```

四层全部暴露，再进入弱点扫描。

---

## 前置：输入长度判断

收到需要拆解的文本后，**第一步**先判断长度：

| 条件 | 路径 |
|------|------|
| 输入文本字符数 < 1500 | 进入 `## 意图问询`（见下方） |
| 输入文本字符数 ≥ 1500 | 移交给 `aolun-fileflow`（文件持久化模式） |

> 判断方法：目测或计数均可。中文500字约等于1500字符，英文250词约等于1500字符，作为参考基准。

长文本强制走 fileflow 的原因：长文本分析产生的中间态报告量大，极易触发 compact，导致上下文丢失。文件落盘是唯一可靠的防御。

---

## 意图问询（短文本路径专用）

> 仅在输入字符数 < 1500 时执行此步骤。长文本已由上一步强制移交给 `aolun-fileflow`，不走此流程。

收到短文本后，在进入调度规则之前，**逐一**询问以下问题。每问一个，等待用户回答后再问下一个。

**如果用户提示词或上下文已明确某个维度，跳过对应问题，记录推断结果，直接进入下一问。**

跳过规则：
- 用户明确说"帮我写反驳/评价/拆解/批判" → Q2 自动选 A，跳过 Q2
- 用户明确说"帮我制定方案/建设路径/下一步" → Q2 自动选 B，跳过 Q2
- 用户明确说"我不太熟悉/我想先了解" → Q1 自动选 B，跳过 Q1
- 路径不含 `aolun-scan-orchestrator`（如纯 build 路径）→ 跳过 Q3

---

### Q1：认识位置

> **你对这个领域/文本有多熟悉？**
>
> A. 基本了解，可以直接进入分析
> B. 不太熟悉，建议先做背景调查（→ 先走 `aolun-ground`）

等待用户回答后，进入 Q2。

---

### Q2：主要目标

> **你的主要目标是什么？**
>
> A. 解剖分析——搞清楚"它到底是什么问题"
> B. 实践建设——知道"下一步应该怎么做"
> C. 两者都要——先分析完，再基于分析结论做建设规划（**顺序执行，非并行**）

等待用户回答后，判断是否需要 Q3。

---

### Q3：执行模式（仅当路径包含 `aolun-scan-orchestrator` 时询问）

> **是否启用 sub-agent 并行执行扫描步骤？**（需要宿主平台支持 agent dispatch）
>
> A. 是，并行执行（推荐，速度更快）
> B. 否，顺序执行

---

### 问询完成后：输出路由决策

根据 Q1/Q2/Q3 答案，从下表确定路径，告知用户后立即开始执行第一个 skill：

| Q1 | Q2 | 路由路径 |
|----|----|---------|
| A（熟悉） | A（分析） | `aolun-dissect-concept` → `aolun-scan-orchestrator` → `aolun-attack` |
| A（熟悉） | B（建设） | `aolun-build` |
| A（熟悉） | C（两者） | `aolun-dissect-concept` → `aolun-scan-orchestrator` → `aolun-attack` → `aolun-build` |
| B（不熟悉） | A（分析） | `aolun-ground` → `aolun-dissect-concept` → `aolun-scan-orchestrator` → `aolun-attack` |
| B（不熟悉） | B（建设） | `aolun-ground` → `aolun-build` |
| B（不熟悉） | C（两者） | `aolun-ground` → `aolun-dissect-concept` → `aolun-scan-orchestrator` → `aolun-attack` → `aolun-build` |

**Q3 横切所有含 `aolun-scan-orchestrator` 的行：** Q3=A 启用并行 dispatch，Q3=B 顺序调用各 scan-* skill。

输出格式：
> 已确认执行路径：[路径描述]
> 现在开始执行，调用 [第一个 skill]。

---

## 调度规则

拿到一篇需要拆解攻击的帖子，标准路径：

```
aolun-arming（路由）
    → aolun-dissect-concept           概念层解剖  ⚡入口
    → aolun-inter-dissect-mechanism   机制层解剖  内部
    → aolun-inter-dissect-constraint  约束层解剖  内部
    → aolun-inter-dissect-interest    利益层解剖  内部
    → aolun-scan-orchestrator  并行扫描编排器（内部并行 dispatch 四个扫描器）⚡入口
    → aolun-other-mountains  跨领域解法引擎  ⚡入口
    → aolun-attack           攻击文生成器  ⚡入口
```

**不需要每次全走。** 判断规则：

| 你的目标 | 最少需要的路径 |
|---------|------------|
| 面对不熟悉领域，需要先建立认识基础（前置） | aolun-ground，再进入下方任一路径 |
| 目标是正向建设方案，不是批判 | aolun-ground → aolun-build |
| 快速摸底一篇帖子 | aolun-dissect-concept + aolun-scan-logic |
| 写一篇有力的技术评论 | 四层解剖 + aolun-scan-orchestrator + aolun-attack |
| 找到真正的跨领域解法 | 四层解剖 + aolun-other-mountains |
| 完整拆底朝天 | 全路径 |

具体步骤、数据传递格式和各工作流的终止条件见 `aolun-workflows`。

---

## 工程领域覆盖范围

本 skill 的专业弹药库覆盖以下工程领域：

- **计算机工程**：软件架构、系统设计、算法、基础设施、AI/ML
- **建筑与土木**：结构体系、材料、施工工艺、城市规划
- **机械工程**：动力系统、传动机构、制造工艺、可靠性
- **自动化与控制**：控制系统、传感器、执行器、工业协议
- **产品设计**：人机工程、材料选择、制造可行性、生命周期

跨领域引用时，必须明确说明**结构相似性**——不是比喻，是真正的机制类比。

---

## 李敖气质的正确用法

李敖的文字有三件武器：

1. **征引**——大量的原始资料，让对方在事实面前无处遁形
2. **解构**——把对方话语里的偷换概念、逻辑跳跃一条一条列出来
3. **反讽**——在证据和逻辑已经胜利之后，用语言给对方一个优雅的羞辱

**顺序不能颠倒。** 没有征引和解构打底，反讽就是耍流氓。

---

## 如何使用各 skill

- **在 Claude Code 中：** 使用 `Skill` 工具调用对应 skill
- **在支持命令的宿主中：** 使用 `commands/` 目录中的手动命令
- **在其他平台：** 直接读取对应 `skills/*/SKILL.md`


| 入口 Skill | 用途 |
|-----------|------|
| `aolun-arming` | 路由器，会话启动，长度判断 |
| `aolun-fileflow` | 文件持久化分析路由器（长文本 ≥1500字符） |
| `aolun-dissect-concept` | 概念层解剖 |
| `aolun-scan-orchestrator` | 并行扫描编排器 |
| `aolun-scan-logic` | 逻辑弱点扫描 |
| `aolun-scan-engineering` | 工程弱点扫描 |
| `aolun-scan-history` | 历史弱点扫描 |
| `aolun-scan-motive` | 动机弱点扫描 |
| `aolun-other-mountains` | 跨领域解法引擎 |
| `aolun-attack` | 攻击文生成器 |
| `aolun-workflows` | 工作流编排 |
| `aolun-ground` | 前置调研 |
| `aolun-build` | 正向实践规划器 |

各 skill 的完整列表和用途说明见 `aolun-workflows`。
