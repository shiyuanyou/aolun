# aolun-prepare-docs 设计

> 日期：2026-04-16
> 状态：设计中

---

## 问题陈述

当前 aolun-fileflow 的 Part 1 承担了文档准备（输入类型判断、文件复制、索引生成）和分析流程编排两类职责。这导致：

1. **职责不清晰**——文档准备逻辑和分析状态管理耦合在同一个 skill 中
2. **复用性差**——用户只想索引一个目录结构而不走分析管线时，没有独立入口
3. **fileflow Part 1 膨胀**——多源输入（快照/引用/单文件/目录）的判断和处理逻辑越来越复杂
4. **活文档场景支持不足**——游戏设计文档等反复迭代的活文档系统需要"准备一次、分析多次"，但 fileflow 每次都从头准备

需要一个独立的文档预处理 skill，将文档准备逻辑从 fileflow 中剥离。

---

## 设计决策

### D1：定位与职责边界

**aolun-prepare-docs 是 ⚡入口 skill，独立调用，不依赖 fileflow。**

| 职责 | 归属 |
|------|------|
| 输入类型判断（文本/路径/目录） | prepare-docs |
| 快照/引用模式选择 | prepare-docs |
| 文件复制（cp）或路径记录 | prepare-docs |
| 索引生成（00-index.md） | prepare-docs |
| 结构标注（标题/公式/表格/代码块位置） | prepare-docs |
| 搜索策略动态生成 | prepare-docs |
| 文件完整性校验（MD5 hash） | prepare-docs |
| 分析状态管理（00-todolist.md） | fileflow |
| 工作流选择与 subagent 调度 | fileflow |
| 步骤执行与摘要提取 | fileflow |

**关键原则：** prepare-docs 的产出和分析状态管理完全解耦。prepare-docs 不知道 fileflow 的存在，fileflow 只消费 prepare-docs 的产出。

### D2：与 fileflow 的关系

```
用户 → aolun-prepare-docs → docs/aolun.skill/<date>-<brief>/
                                      ├── 00-original.md 或 00-sources/
                                      ├── 00-index.md
                                      └── 00-prep-meta.md

用户 → aolun-fileflow → 检测到 prepare-docs 产出？
                         ├── 是 → 跳过文档准备，读取 00-prep-meta.md，创建 00-todolist.md，进入工作流选择
                         └── 否 → 执行内联简化文档准备（仅粘贴文本场景），创建 00-todolist.md，进入工作流选择
```

**fileflow 不调用 prepare-docs skill。** fileflow 内联了一套简化版的文档准备逻辑（只处理粘贴文本场景）。多源输入、快照/引用等复杂场景需要用户先手动调用 prepare-docs。

两者共享相同的目录结构（`docs/aolun.skill/<date>-<brief>/`）和文件格式，但没有运行时依赖。

### D3：输入形态处理

| 输入形态 | 判断条件 | 存储模式 | prepare-docs 动作 |
|---------|---------|---------|-------------------|
| 粘贴文本 | 无路径特征 | 快照 | 原文写入 `00-original.md` |
| 单文件 .md 快照 | 路径指向一个 .md 文件，用户选快照 | 快照 | cp 为 `00-original.md` |
| 单文件 .md 引用 | 同上，用户选引用 | 引用 | 不复制，路径记录到 `00-prep-meta.md` |
| 目录快照 | 路径指向目录，用户选快照 | 快照 | cp -r 为 `00-sources/`，生成 `00-index.md` |
| 目录引用 | 同上，用户选引用 | 引用 | 不复制，生成 `00-index.md`（指向源目录） |
| 非 .md | 其他文件格式 | — | 报错提示，退出流程 |

**快照/引用选择规则：**
- 粘贴文本 → 默认快照（无选择）
- 单文件路径 → 询问用户
- 目录路径 → 询问用户

**路径判断规则：**
- 以 `/` 开头：绝对路径
- 以 `~` 开头：家目录路径
- 以 `./` 或 `../` 开头：相对路径
- 包含文件扩展名（`.md`、`.txt` 等）且无连续段落文本特征
- 以路径分隔符结尾（目录标识）

### D3.1：异常处理

| 场景 | 处理 |
|------|------|
| 路径不存在 | 输出"文件/目录不存在：<路径>"，终止 |
| 目录为空或无 .md 文件 | 输出"目录下未找到 Markdown 文件：<路径>"，终止 |
| cp 失败（权限等） | 输出错误信息，终止 |
| 目录 > 50 个 .md 文件 | 警告"检测到 <N> 个 Markdown 文件，可能耗时较长。是否继续？[继续] [选择子集]" |

### D4：快照模式 vs 引用模式

#### 快照模式

- 单文件：`cp <源文件> <任务目录>/00-original.md`
- 目录：`cp -r <源目录> <任务目录>/00-sources/`
- 源文件变更不影响已复制版本
- 适合一次性分析外部帖子

#### 引用模式

- 不复制文件，`00-prep-meta.md` 记录源路径
- subagent 直接读取源路径
- 源文件变更会反映在读取中（活文档场景的预期行为）
- `00-prep-meta.md` 记录启动时各源文件 MD5 hash
- fileflow 或 subagent 读取时比对 hash，不匹配则警告

#### 引用模式 + 外部 index

如果用户的文档系统已有 index 文件：

```markdown
## 源信息
- 输入形态：目录引用
- 源目录：/path/to/game-design/
- 外部索引：/path/to/game-design/index.md
- aolun 索引：<任务目录>/00-index.md
```

用户可选择让 aolun 直接使用现有 index（跳过自动生成），或让 aolun 基于 00-index.md 模板重新生成结构索引。

### D5：产出文件格式

#### 00-prep-meta.md

```markdown
# 文档准备元信息 — <brief>

> 准备时间：<yyyy-mm-dd HH:MM>
> 输入形态：[粘贴 / 单文件快照 / 单文件引用 / 目录快照 / 目录引用]
> 存储模式：[快照 / 引用]
> 任务目录：docs/aolun.skill/<yyyy-mm-dd>-<brief>/

## 源信息

- 源路径：<绝对路径>（引用模式时有值；快照模式时为空或记录原始路径用于溯源）
- 总行数：<自动统计>
- 文件数：<N>（目录模式时有值）
- 外部索引：<用户提供路径 或 无>

## 文件完整性

| 文件 | MD5 | 备注时间 |
|------|-----|---------|
| 00-original.md | <hash> | <时间戳> |
| 或 00-sources/*.md | <各文件hash> | <时间戳> |

（引用模式下，hash 为源文件的 hash，非复制品）

## 搜索策略

<根据原文内容动态生成，详见 D6>
```

**设计意图：** `00-prep-meta.md` 的生命周期和 `00-todolist.md` 分离——元信息在文档准备时确定后不变，分析状态随步骤推进变化。fileflow 创建 `00-todolist.md` 时从 `00-prep-meta.md` 读取搜索策略填充。

#### 00-original.md

纯原文，无 header 注释，第 1 行就是原文第 1 行。

溯源信息记录在 `00-prep-meta.md`，不污染原文。

#### 00-sources/

目录快照模式下，原始目录的完整拷贝（仅 .md 文件）。

目录引用模式下，此目录不存在，subagent 直接读取源路径。

#### 00-index.md

```markdown
# 原文索引 — <brief>

> 源目录：00-sources/（快照模式）或 <源目录绝对路径>（引用模式）
> 文件数：<N> 个 .md 文件
> 总行数：<M>

## 文件清单

| # | 文件路径 | 行数 | 摘要（前50字符） |
|---|---------|------|--------------|
| 1 | 00-sources/index.md | 45 | 入口索引文件 |
| 2 | 00-sources/ch01-intro.md | 320 | 引言，核心声称 |

## 结构索引

[跨所有 .md 文件扫描标题/表格/公式/代码块，标注 文件名:行号]

- 章节标题：搜索 "^#+ "
- 数学公式块：搜索 "$$" 或 "\\["
- 表格：搜索 "^|" 或 "表\\d"
- 代码块：搜索 "```"

## 语义线索

<预留，由 aolun-dissect-concept 完成后追加>
```

**00-index.md 生成步骤：**

```
1. bash: ls <源路径或任务目录>/00-sources/*.md（或源目录） → 文件列表
2. bash: wc -l <文件列表> → 行数 + 总行数
3. grep -n '^#+ ' <文件列表> → 章节标题索引
4. grep -n '^\|' <文件列表> → 表格行号
5. grep -n '```' <文件列表> → 代码块行号
6. grep -n '\$\$' <文件列表> → 数学公式块行号
7. 对每个文件 Read 前 3-5 行 → 摘要
```

### D6：搜索策略动态生成

prepare-docs 从原文内容自动生成初版搜索策略，写入 `00-prep-meta.md`：

```
搜索策略生成规则：

1. 从 00-original.md 或 00-index.md 的结构索引中提取高频术语
   - grep 所有标题中的关键词
   - 统计出现频率 > 2 的术语
   - 取前 10 个作为领域关键词

2. 从标题中提取核心概念
   - 一级标题通常是核心声称
   - 二级标题通常是子主题

3. 生成领域相关搜索策略（3-5 条）
   - 每条策略包含：目标类型 + 搜索关键词
   - 示例：核心声称 → 搜索"提出认为表明证明"

4. 附加跨领域通用策略（3 条固定）
   - 核心声称定位：搜索 "提出"、"认为"、"表明"、"证明"
   - 数据和证据定位：搜索数字、百分比模式、引用来源标记
   - 定义关键术语：搜索 "所谓"、"定义为"、"是指"

5. 概念层解剖完成后，aolun-fileflow 用语义线索更新 00-todolist.md 的搜索策略
```

fileflow 创建 `00-todolist.md` 时，从 `00-prep-meta.md` 的搜索策略部分读取并填充。

### D7：Skill 元数据

```yaml
name: aolun-prepare-docs
description: |
  ⚡入口 skill。将任意输入（文本、文件路径、目录路径）转化为 aolun 分析管线可消费的标准文档结构。
  支持快照模式（cp 到任务目录）和引用模式（直接读取源路径），生成索引、结构标注、搜索策略和文件完整性校验。
  产出文件供 aolun-fileflow 直接消费，也可独立用于任何需要 Markdown 文档索引的场景。
  English: Entry skill. Transforms any input (text, file path, directory path) into a standard document structure consumable by the aolun analysis pipeline.
  Supports snapshot mode (copy to task directory) and reference mode (read source paths directly). Generates index, structural annotations, search strategies, and file integrity checksums.
  Output files are consumed by aolun-fileflow, or used independently for any scenario requiring Markdown document indexing.
```

### D8：对 fileflow 的改动

fileflow Part 1 启动阶段修改如下：

**原流程：**
1. 提取 brief → 2. 创建任务目录 + 保存 00-original.md → 3. 创建 00-todolist.md → 4. 崩溃恢复检测 → 5. 询问工作流

**新流程：**
1. 提取 brief → 2. **检测任务目录中是否已有 00-prep-meta.md**
   - 有 → 读取输入形态和索引信息，跳过文档准备 → 创建 00-todolist.md（从 00-prep-meta.md 读取搜索策略）
   - 无 → 执行内联简化文档准备（仅支持粘贴文本场景）→ 创建 00-original.md → 创建 00-todolist.md
3. 崩溃恢复检测 → 4. 询问工作流

**fileflow 内联简化文档准备** 只处理：
- 粘贴文本 → 直接写入 00-original.md
- 其他形态 → 提示用户先调用 aolun-prepare-docs

### D9：引用格式

引用格式规范与 fileflow spec v2 D5 一致：

| 模式 | 引用格式 | 示例 |
|------|---------|------|
| 单文件 | `第<N>行："直接引用原句"` | `第42行："Scaling Law 已经触顶"` |
| 目录模式 | `文件名:<N>："直接引用原句"` | `ch02-method.md:42："Scaling Law 已经触顶"` |
| 连续行范围 | `第<N>-<M>行` 或 `文件名:<N>-<M>："..."` | `第42-45行` 或 `ch02.md:42-45："..."` |

格式规范：行号前半角冒号 `:`，引用内容中文引号 `""`，范围半角连字符 `-`。

---

## 改动清单

| # | 文件 | 改动类型 | 改动内容 |
|---|------|---------|---------|
| 1 | `skills/aolun-prepare-docs/SKILL.md` | 新增 | 完整 skill 定义 |
| 2 | `skills/aolun-fileflow/SKILL.md` | 修改 | Part 1 增加 prepare-docs 产出检测逻辑；内联简化文档准备；创建 00-todolist.md 时从 00-prep-meta.md 读取搜索策略 |
| 3 | `skills/aolun-arming/SKILL.md` | 修改 | 前置判断增加路径检测（D10 of spec v2） |

---

## 不改动的文件

| 文件 | 理由 |
|------|------|
| 6 个解剖/攻击/他山之石 skill | fileflow 模式说明小节由 fileflow spec v2 覆盖，不在本 spec 范围 |
| 4 个扫描器 skill | 同上 |
| `skills/aolun-workflows/SKILL.md` | 描述内存模式工作流 |
| `skills/aolun-ground/SKILL.md` | 独立路径 |
| `skills/aolun-build/SKILL.md` | 独立路径 |
| `skills/aolun-scan-orchestrator/SKILL.md` | dispatch 模板由 fileflow spec v2 覆盖 |

---

## 验证标准

### 自动化验证

1. `npm test` 通过（frontmatter 合法性、必需文件存在）
2. 新 skill `aolun-prepare-docs` 出现在 skill 列表中

### 功能验证

3. prepare-docs 独立调用：粘贴文本 → 生成 00-original.md + 00-prep-meta.md（无 00-index.md）
4. prepare-docs 独立调用：单文件快照 → cp 为 00-original.md + 00-prep-meta.md
5. prepare-docs 独立调用：单文件引用 → 不复制，00-prep-meta.md 记录源路径 + hash
6. prepare-docs 独立调用：目录快照 → cp 为 00-sources/ + 00-index.md + 00-prep-meta.md
7. prepare-docs 独立调用：目录引用 → 不复制，生成 00-index.md + 00-prep-meta.md
8. prepare-docs 独立调用：非 .md 文件 → 报错退出
9. prepare-docs 独立调用：路径不存在 → 报错退出
10. prepare-docs 独立调用：目录 > 50 个 .md → 警告并询问

### 集成验证

11. prepare-docs 产出 → fileflow 检测到 00-prep-meta.md → 跳过文档准备，正确创建 00-todolist.md
12. fileflow 无 prepare-docs 产出 + 粘贴文本 → 内联简化流程正常工作
13. fileflow 无 prepare-docs 产出 + 文件路径 → 提示用户先调用 prepare-docs
14. 引用模式下源文件变更 → subagent 读取时 hash 不匹配 → 警告
15. 00-original.md 无 header 注释，第 1 行 = 原文第 1 行
16. 引用格式正确：单文件 `第N行"..."`，目录 `文件名:N"..."`