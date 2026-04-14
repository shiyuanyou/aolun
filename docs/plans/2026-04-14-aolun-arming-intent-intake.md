# aolun-arming 意图问询模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `aolun-arming` 的短文本路径（<1500字符）中，插入意图问询模块（Q1/Q2/Q3三问），并根据答案输出明确的路由决策，取代现有的直接跳转至调度规则的行为。

**Architecture:** 纯 Markdown skill 编辑。在现有 `## 前置：输入长度判断` 块与 `## 调度规则` 块之间插入新的 `## 意图问询` 块；同时更新长度判断表格中 <1500 行的描述，使其指向意图问询而非直接指向调度规则。不涉及任何可执行代码变更。

**Tech Stack:** Markdown，`npm test`（`bash tests/validate.sh`）作为验证工具

---

### Task 1：更新长度判断表格的 <1500 行描述

**Files:**
- Modify: `skills/aolun-arming/SKILL.md:63-66`

- [ ] **Step 1：定位目标行**

  打开 `skills/aolun-arming/SKILL.md`，找到第63–66行的长度判断表格：

  ```markdown
  | 条件 | 路径 |
  |------|------|
  | 输入文本字符数 < 1500 | 继续走下方调度规则（内存执行模式） |
  | 输入文本字符数 ≥ 1500 | 移交给 `aolun-fileflow`（文件持久化模式） |
  ```

- [ ] **Step 2：修改 <1500 行的描述**

  将 `继续走下方调度规则（内存执行模式）` 改为 `进入 ## 意图问询（见下方）`：

  ```markdown
  | 条件 | 路径 |
  |------|------|
  | 输入文本字符数 < 1500 | 进入 `## 意图问询`（见下方） |
  | 输入文本字符数 ≥ 1500 | 移交给 `aolun-fileflow`（文件持久化模式） |
  ```

- [ ] **Step 3：运行验证**

  ```bash
  npm test
  ```

  预期输出：`All checks passed. aolun is ready.`

- [ ] **Step 4：提交**

  ```bash
  git add skills/aolun-arming/SKILL.md
  git commit -m "feat: update length routing table to point to intent intake"
  ```

---

### Task 2：插入 `## 意图问询` 块

**Files:**
- Modify: `skills/aolun-arming/SKILL.md:72`（在 `## 调度规则` 之前插入新块）

- [ ] **Step 1：确认插入位置**

  目标位置是现有第72行 `---`（`## 前置：输入长度判断` 块结束后的分隔线）与第74行 `## 调度规则` 之间。

  当前该区域内容（第70–75行）：
  ```
  长文本强制走 fileflow 的原因：...
  
  ---
  
  ## 调度规则
  ```

- [ ] **Step 2：在 `## 调度规则` 之前插入完整的意图问询块**

  在第72行 `---` 之后、第74行 `## 调度规则` 之前，插入以下内容：

  ````markdown
  
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
  
  ````

- [ ] **Step 3：运行验证**

  ```bash
  npm test
  ```

  预期输出：`All checks passed. aolun is ready.`

- [ ] **Step 4：人工检查结构**

  确认 `aolun-arming/SKILL.md` 中区块顺序正确：
  1. `## 前置：输入长度判断`（现有，已更新 <1500 行）
  2. `## 意图问询（短文本路径专用）`（新增）
  3. `## 调度规则`（现有，未变）

- [ ] **Step 5：提交**

  ```bash
  git add skills/aolun-arming/SKILL.md
  git commit -m "feat: add intent intake module to aolun-arming

  - Insert ## 意图问询 block between length check and dispatch rules
  - Q1 maps to 实践论 感性认识位置
  - Q2 maps to 矛盾论 主要矛盾识别 (分析/建设/两者顺序执行)
  - Q3 controls sub-agent parallel mode for scan-orchestrator paths
  - Full 6-row routing matrix covering Q1×Q2 combinations
  - Q3 as cross-cutting concern on all paths containing scan-orchestrator"
  ```

---

### Task 3：验证完整文件并运行最终检查

**Files:**
- Read: `skills/aolun-arming/SKILL.md`（验证读）

- [ ] **Step 1：通读修改后的完整文件**

  确认以下内容全部存在且位置正确：
  - `## 前置：输入长度判断` 表格中 <1500 行的描述已改为 `进入 \`## 意图问询\`（见下方）`
  - `## 意图问询（短文本路径专用）` 块完整存在，包含：
    - 跳过规则列表（4条）
    - Q1 问题与选项 A/B
    - Q2 问题与选项 A/B/C（含 C 的顺序执行说明）
    - Q3 问题与选项 A/B（含触发条件说明）
    - 6行路由矩阵
    - Q3 横切说明
    - 输出格式模板
  - `## 调度规则` 块保持原样

- [ ] **Step 2：运行最终验证**

  ```bash
  npm test
  ```

  预期输出：`All checks passed. aolun is ready.`

- [ ] **Step 3：确认提交历史清晰**

  ```bash
  git log --oneline -3
  ```

  预期看到：
  ```
  <sha> feat: add intent intake module to aolun-arming
  <sha> feat: update length routing table to point to intent intake
  <sha> docs: add intent intake design spec for aolun-arming
  ```
