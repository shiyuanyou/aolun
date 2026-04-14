# aolun-fileflow 设计文档

> 日期：2026-04-14  
> 状态：已确认，待实现

---

## 背景与目标

长文本分析（字符数 ≥ 1500）会产生大量中间态报告，极易触发 compact 导致上下文丢失。
本设计引入文件持久化分析路由器 `aolun-fileflow`，将每个 skill 的输出落盘为独立文件，
每步完成后暂停等待用户确认，最终整合为完整分析文档。

---

## 改动范围

两个文件变更：

1. **修改** `skills/aolun-arming/SKILL.md` — 增加前置长度判断
2. **新建** `skills/aolun-fileflow/SKILL.md` — 文件持久化分析路由器

---

## 改动 1：`aolun-arming` 的修改

### 修改位置

在现有 `## 调度规则` 部分之前插入新的 `## 前置：输入长度判断` 块。
原有内容一字不动。

### 插入内容

```markdown
## 前置：输入长度判断

收到需要拆解的文本后，**第一步**先判断长度：

| 条件 | 路径 |
|------|------|
| 输入文本字符数 < 1500 | 继续走下方调度规则（内存执行模式） |
| 输入文本字符数 ≥ 1500 | 移交给 `aolun-fileflow`（文件持久化模式） |

> 判断方法：目测或计数均可。中文500字约等于1500字符，英文250词约等于1500字符，作为参考基准。

长文本强制走 fileflow 的原因：长文本分析产生的中间态报告量大，
极易触发 compact，导致上下文丢失。文件落盘是唯一可靠的防御。
```

---

## 改动 2：`aolun-fileflow` 新建 Skill

### Frontmatter

```yaml
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
```

### Part 1：启动阶段

1. 从输入文本**前50字符**提取 `<brief>`：
   - 去除标点和特殊字符
   - 转小写，空格替换为连字符
   - 截断到合理长度（约20字符）
   - 示例：`"大语言模型的 Scaling Law 已经..."` → `da-yuyan-moxing-scaling-law`

2. 创建任务目录：
   ```
   docs/aolun.skill/<yyyy-mm-dd>-<brief>/
   ```

3. 询问用户选择工作流：
   - **Workflow 2（标准拆解）**：完整四层解剖 + 并行扫描 + 可选他山之石 + 攻击文
   - **Workflow 3（底朝天全拆）**：同上，但每层解剖更深，扫描后增加跨领域引用验证

4. 展示执行计划（步骤序号 + 名称），等待用户确认开始。

---

### Part 2：逐步执行规则

每个步骤的统一执行模式：

```
① 执行当前 skill（传入原始文本 + 上一步文件路径作为上下文）
② 将完整输出写入 <NN>-<skill-name>.md
③ 用 grep/sed 从文件中提取摘要：
     提取规则：找到最后一个以【开头的块，取该块内最后一个非空行
④ 在对话中展示摘要（不展示全文）
⑤ 暂停，显示操作提示：
     [继续] 执行下一步
     [修改] 提出修改意见 → 重新执行 → 覆盖写入文件 → 再次展示摘要
     [跳过] 跳过下一步（在下一个文件头部注释中记录跳过原因）
     [结束] 停在当前步骤，不继续
```

---

### Part 3：步骤序列定义

#### Workflow 2 步骤序列

| 文件名 | 调用 Skill | 备注 |
|--------|-----------|------|
| `01-dissect-concept.md` | `aolun-dissect-concept` | 必须 |
| `02-dissect-mechanism.md` | `aolun-inter-dissect-mechanism` | 必须 |
| `03-dissect-constraint.md` | `aolun-inter-dissect-constraint` | 必须 |
| `04-dissect-interest.md` | `aolun-inter-dissect-interest` | 必须 |
| `05-scan-summary.md` | `aolun-scan-orchestrator` | 必须，并行扫描综合报告 |
| `06-other-mountains.md` | `aolun-other-mountains` | 可选，询问用户是否执行 |
| `07-attack.md` | `aolun-attack` | 必须 |
| `99-final-<slug>.md` | — | 用户选择整合时生成 |

#### Workflow 3 步骤序列

同 Workflow 2，但在 05 和 06 之间增加：
- `05b-scan-deep-verify.md`：对扫描结果中证据不足的条目补充一轮深度调查

---

### Part 4：文件格式规范

#### 中间态文件格式

```markdown
# <skill名称> — <任务brief>

> 执行时间：<yyyy-mm-dd HH:MM>
> 输入来源：原始文本 / <上一步文件名>
> 状态：完成 / 已修改（第N次）/ 已跳过

---

<skill 完整输出>
```

#### 摘要提取规则（grep/sed）

从文件中提取对话展示用的摘要：

```bash
# 提取最后一个【...】块内的最后一个非空行
grep -n "^【" <file> | tail -1  # 找到最后一个【块的行号
# 从该行号到文件末尾，取最后一个非空行
```

具体实现由执行平台的工具完成（Bash tool 的 grep/sed）。

---

### Part 5：整合规则

用户选择整合后：

1. `<slug>` 由用户指定，或默认使用 `<brief>`
2. 按序读取所有编号文件（`01-` 到 `07-`，跳过标记为"已跳过"的）
3. 写入 `99-final-<slug>.md`，格式如下：

```markdown
# <slug> — 完整分析

> 整合时间：<yyyy-mm-dd HH:MM>
> 任务目录：docs/aolun.skill/<yyyy-mm-dd>-<brief>/
> 包含步骤：01-dissect-concept, 02-dissect-mechanism, ...

---

<按顺序拼接各步骤完整内容，各步骤间用 --- 分隔>

---

## 整体摘要

> 从各步骤文件中 grep 提取的综合判断，逐条列出：

- **概念层**：<01 文件的综合判断行>
- **机制层**：<02 文件的综合判断行>
- **约束层**：<03 文件的综合判断行>
- **利益层**：<04 文件的综合判断行>
- **扫描综合**：<05 文件的最致命一击>
- **攻击文定性**：<07 文件的定性结论行>
```

---

## 目录结构总览

```
docs/aolun.skill/
└── <yyyy-mm-dd>-<brief>/
    ├── 01-dissect-concept.md
    ├── 02-dissect-mechanism.md
    ├── 03-dissect-constraint.md
    ├── 04-dissect-interest.md
    ├── 05-scan-summary.md
    ├── 06-other-mountains.md     ← 可选
    ├── 07-attack.md
    └── 99-final-<slug>.md        ← 整合后生成
```

---

## 设计约束

- `aolun-fileflow` 是纯 Markdown 指令集，不含可执行代码
- 文件操作（创建目录、写文件、grep 提取）由宿主 agent 的工具完成
- 所有 skill 调用仍遵循原有的数据传递规范（见 `aolun-workflows`）
- 跳过某步骤时，下游 skill 应注意输入缺失，降级处理而非报错

---

## 验证标准

实现完成后，`npm test`（`tests/validate.sh`）应通过：
- `skills/aolun-fileflow/SKILL.md` 存在且有合法 frontmatter
- `aolun-arming` frontmatter 保持合法
- 新 skill 出现在 skill 列表中
