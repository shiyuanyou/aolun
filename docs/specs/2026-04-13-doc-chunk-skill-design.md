# Design: doc-chunk Skill System

**Date:** 2026-04-13  
**Status:** Draft  
**Scope:** 通用文档预处理层——将长文档转换为 subagent 可按需寻址的分块知识库

---

## 1. 问题陈述

在 aolun 的扫描层（aolun-scan-orchestrator）dispatch subagent 时，subagent 是全新空白会话，主 agent 通过工具读取的文档内容对它不可见。当前唯一的传递方式是在 dispatch prompt 中内嵌文字，这导致：

- 长文档（论文、技术规范、合同）被迫在主 agent 侧压缩为摘要再传递
- subagent 缺少原文引用能力，扫描报告中"原文证据"字段空洞或捏造
- 实验数据、方法论细节、特定条款等高密度信息大量丢失

**本质：** subagent 需要的是一个它自己可以寻址的持久化知识库，而不是主 agent 帮它摘好的信息。

---

## 2. 目标

- 将任意长文档（PDF/Word/txt/md）转换为按任务类型优化的分块文件集
- 生成轻量索引文件（`00_index.md`），让 subagent 用 ~200 token 决定读哪几块
- 每块大小控制在 subagent 安全 context 范围内（默认上限 4000 token/块）
- 支持多种文档类型：学术论文、技术文档、法律合同（可扩展）
- 与 aolun 扫描流程无缝集成，也可独立使用

---

## 3. 架构概览

```
用户提供文档（PDF/Word/txt）
         ↓
   [doc-prepare]           ← 入口 skill：检测文档类型，路由到具体分块器
         ↓
[doc-chunk-academic]       ← 学术论文分块器
[doc-chunk-technical]      ← 技术文档分块器  
[doc-chunk-legal]          ← 法律/合同分块器
         ↓
   scripts/chunk.py        ← 共用执行脚本（接受策略参数）
         ↓
  {output_dir}/
    ├── 00_index.md         ← 轻量索引（subagent 入口）
    ├── 01_{title}.md
    ├── 02_{title}.md
    └── ...
         ↓
   subagent 启动时：
     1. Read 00_index.md（轻量）
     2. 根据任务判断需要哪几块
     3. 只 Read 需要的 chunk
     4. 输出结构化摘要返回上层
```

---

## 4. Skill 层设计

### 4.1 `doc-prepare`（路由入口）

**职责：**
1. 接收文档路径
2. 检测文档类型（依据：文件扩展名 + 内容特征词）
3. 估算总 token 数（调用 `scripts/chunk.py --estimate`）
4. 路由到对应的 `doc-chunk-*` skill
5. 报告输出目录路径

**类型检测规则：**

| 特征 | 判定类型 |
|------|---------|
| 包含 Abstract / Methods / Results / References | academic |
| 包含 API / Installation / Configuration / Usage | technical |
| 包含 甲方/乙方 / 条款 / 违约 / 协议 / Party A | legal |
| 无法判定 | 默认 technical |

**输出给用户：**
```
检测结果：[类型]
总 token 估算：[N]
预计分块数：[N]
输出目录：[path]
调用：doc-chunk-[type]
```

---

### 4.2 `doc-chunk-academic`（学术论文分块器）

**分块策略：**
- 一级切割：按论文结构段落（Abstract / Introduction / Related Work / Methods / Results / Discussion / Conclusion / References）
- 二级切割：超过 4000 token 的段落按子标题再切
- 特殊处理：Tables 和 Figures 的 caption + 数据独立为一块（`XX_tables_figures.md`）

**index_brief 着重点（每块的索引条目包含）：**
- 块标题
- 50 字内容摘要
- **关键数值列表**（实验结果、样本量、p值、精度等）— 学术场景专属
- token 数
- 文件路径

**index 示例：**
```markdown
## 03_results.md — Results
**摘要：** 在三个基准数据集上评估，提出方法在 BLEU、ROUGE 指标上均优于 baseline。
**关键数值：** BLEU=42.3, ROUGE-L=38.7, n=1240, p<0.001, 相比 baseline +8.2%
**Token：** 2840
**路径：** chunks/03_results.md
```

---

### 4.3 `doc-chunk-technical`（技术文档分块器）

**分块策略：**
- 一级切割：按一级标题（`#`）
- 二级切割：超过 4000 token 的章节按二级标题（`##`）再切
- 特殊处理：代码块完整保留（不在代码块中间切割）

**index_brief 着重点：**
- 块标题
- 50 字摘要
- **技术关键词列表**（核心 API、配置项、依赖项）
- token 数
- 文件路径

---

### 4.4 `doc-chunk-legal`（法律/合同分块器）

**分块策略：**
- 一级切割：按条款编号（第X条 / Article X / Section X）
- 二级切割：超过 4000 token 的条款按子条款切
- 特殊处理：定义条款（Definitions）独立为首块

**index_brief 着重点：**
- 条款编号 + 标题
- 50 字摘要
- **风险标记**（违约责任/赔偿条款/限制条款 用 ⚠️ 标注）
- token 数
- 文件路径

---

## 5. 脚本层设计（`scripts/chunk.py`）

**接口：**

```bash
# 估算模式（不写文件）
python chunk.py --input paper.pdf --mode estimate

# 执行分块
python chunk.py --input paper.pdf --strategy academic --output ./chunks --max-tokens 4000

# 支持的输入格式
# .pdf   → 用 pdfminer.six 或 pymupdf 提取文本
# .docx  → 用 python-docx 提取文本
# .txt   → 直接读
# .md    → 直接读（保留结构）
```

**依赖：**
```
pdfminer.six    # PDF 文本提取
python-docx     # Word 文档提取
tiktoken        # token 计数（OpenAI tokenizer，近似估算）
```

**输出目录结构：**
```
{output_dir}/
  00_index.md           ← 索引文件
  01_{slug}.md          ← 各 chunk（slug 从标题生成）
  .doc-chunk-meta.json  ← 元数据（原文件名、策略、时间戳、总token）
```

---

## 6. subagent 启动 prompt 模板

当 orchestrator dispatch subagent 时，使用以下模板替代内嵌原文：

```
【文档索引路径】{output_dir}/00_index.md

你的任务开始前，请：
1. 先 Read {output_dir}/00_index.md，了解文档结构和各块内容
2. 根据你的扫描任务，判断需要读取哪几个 chunk
3. 用 Read 工具读取相关 chunk
4. 执行扫描，引用时注明 chunk 文件名和原文

【你的任务】
[扫描器类型和具体指令]
```

---

## 7. 与 aolun 的集成点

### 在 aolun-workflows 中的位置

```
[doc-prepare]                    ← 新增：论文/文档输入前置步骤
    ↓ 生成 chunks/ 目录
aolun-dissect-concept
    → aolun-inter-dissect-mechanism
    → aolun-inter-dissect-constraint
    → aolun-inter-dissect-interest
    ↓
aolun-scan-orchestrator          ← dispatch prompt 改为传 chunks/ 路径
    → subagent 自主 Read 所需 chunk
```

### aolun-scan-orchestrator 的 dispatch prompt 变化

**当前（传全文或摘要）：**
```
原始帖子：[粘贴完整原文或摘要]
```

**集成后（传索引路径）：**
```
文档已预处理。索引：{chunks_dir}/00_index.md
先读索引，按需读 chunk，再执行扫描。
```

---

## 8. 文件结构

```
skills/
  doc-prepare/
    SKILL.md
  doc-chunk-academic/
    SKILL.md
  doc-chunk-technical/
    SKILL.md
  doc-chunk-legal/
    SKILL.md
scripts/
  chunk.py
  requirements.txt
  configs/
    academic.yaml     ← 分块参数（max_tokens, split_on, index_fields）
    technical.yaml
    legal.yaml
```

---

## 9. 开放问题（待决策）

| 问题 | 选项 | 当前倾向 |
|------|------|---------|
| chunk 目录放在哪里 | 文档旁边 / 固定的 `.cache/doc-chunks/` / 用户指定 | 用户指定，默认文档同目录下的 `chunks/` |
| PDF 提取质量 | pdfminer（轻量） vs pymupdf（更准但需编译） | pdfminer 优先，降级提示用户转 txt |
| token 计数方案 | tiktoken（OpenAI）/ 字符数估算（4字符≈1token） | tiktoken，无法安装时降级到字符估算 |
| 是否支持图表 OCR | 不支持（只提取文字） / 支持（需 tesseract） | 不支持，caption 文字保留即可 |
| chunk 大小上限 | 2000 / 4000 / 8000 token | 4000（保守，给 subagent 留足推理空间） |

---

## 10. 成功标准

- [ ] subagent 扫描报告中的「原文引用」字段有具体原文（非捏造）
- [ ] 实验数据（数值、样本量、显著性）能被正确引用
- [ ] 一篇 30 页学术论文能在 60 秒内完成预处理
- [ ] `npm test` 通过（新 skill 的 frontmatter 格式合规）
- [ ] doc-prepare skill 可独立于 aolun 使用（无 aolun 依赖）
