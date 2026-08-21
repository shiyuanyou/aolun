# aolun v2 简化方案

> 创建时间：2026-08-21
> 状态：已完成（2026-08-21；S14 全流程验收通过；validate 全绿；push 待 GitHub 凭证）
> 决策：采用两段式（`aolun-dissect` + `aolun-scan`），`aolun-workflows` 弱化为路由说明并入编排层
> 参照：enloom v1.0 → v1.3 清零重写 / 单一 skill / checkpoint = 阶段结束 / 归档旧物

---

## 1. 背景与问题

在 `guangzhou-state-capital-token` 默认等人测试中观察到：

- 同一批证据和结论在 4 层解剖和 4 维扫描中反复出现，只是换措辞。
- 债区大量“承接 #N”，重复登记多、阅读负担大。
- 标准流程需要 7 个文件、2 次大汇报，实际信息增量远低于文件数。
- 当前 skill 家族偏重“流水线仪式”，不符合 enloom 最近重构强调的“只锁住容易丢的全局信息，普通细节交给模型涌现”。

## 2. 目标

1. 把默认分析流水线从“4 层 + 4 维 + orchestrator”压成“1 次拆解 + 1 次扫描”。
2. 每个维度只输出增量发现，重复结论不重复展开。
3. 债区天然去重。
4. checkpoint 对齐 enloom v1.2：阶段结束，沉默 ≠ 继续。
5. 旧 skill 归档保留，不删除历史证据。

## 3. 目标 skill 架构

### 核心分析（保留/新增）

| Skill | 定位 |
|-------|------|
| `aolun-dissect` | 新增，替代 4 个 dissect-*；一次输出概念/机制/约束/利益四小节 |
| `aolun-scan` | 新增，替代 4 个 scan-* + orchestrator；一次输出逻辑/工程/历史/动机四小节 |
| `aolun-other-mountains` | 保留，可选跨领域解法 |
| `aolun-attack` | 保留，攻击文 |
| `aolun-build` | 保留，正向建设 |

### 编排/辅助（保留或弱化）

| Skill | 定位 |
|-------|------|
| `aolun-fileflow` | 保留，长文本路由/落盘/债区/checkpoint 的唯一编排器 |
| `aolun-prepare-docs` | 保留，文档准备 |
| `aolun-ground` | 保留，陌生领域前置感知 |
| `aolun-arming` | 保留，顶层路由与总原则 |
| `aolun-workflows` | 弱化：不再作为独立默认入口，预设菜单内容并入 `aolun-fileflow` 与 `aolun-arming` |

### 归档（不参与新流水线）

- `aolun-dissect-concept`
- `aolun-inter-dissect-mechanism`
- `aolun-inter-dissect-constraint`
- `aolun-inter-dissect-interest`
- `aolun-scan-logic`
- `aolun-scan-engineering`
- `aolun-scan-history`
- `aolun-scan-motive`
- `aolun-scan-orchestrator`

归档位置：`skills/_archive/`（repo 内保留 git 历史，正文不动）。

## 4. 新流程定义

### Workflow 1：快速狙击

```
01-dissect.md（轻量模式，只做概念+逻辑增量）
02-attack.md（50-200 字）
```

### Workflow 2：标准拆解（默认）

```
01-dissect.md
02-scan.md
03-other-mountains.md（可选）
04-attack.md
```

### Workflow 3：底朝天全拆

```
01-dissect.md
02-scan.md
02b-deep-verify.md（仅证据不足维度触发，可选）
03-other-mountains.md（可选）
04-attack.md
```

### 关键节点

- 解剖完成（`01-dissect.md` 后）停一次。
- 扫描完成（`02-scan.md` 后）停一次。
- 进入攻击/整合前停一次。
- 出现阻塞型路线变化随时停。

## 5. `aolun-dissect` 规格

- 输入：`00-original.md` + `00-index.md` + `00-todolist.md`
- 输出：`01-dissect.md`
- 内部结构：
  1. 概念层：核心声称、定义自洽、术语偷换
  2. 机制层：因果链、可行性、关键假设
  3. 约束层：成立条件、边界、超界后果
  4. 利益层：谁在推、得到什么、隐藏了什么
- 纪律：
  - 四小节共享同一证据池。
  - 后一节只写“前一节未覆盖的增量发现”。
  - 重复结论用 `同源 #N` 指向已有小节，不重复展开。
  - 所有判断必须带原文行号 + 直接引用。
- 输出顶部必须有【摘要】块（3-5 行）。

## 6. `aolun-scan` 规格

- 输入：`01-dissect.md` + `00-original.md` + `00-todolist.md`
- 输出：`02-scan.md`
- 内部结构：
  1. 逻辑扫描：推论跳跃、循环论证、错误类比
  2. 工程扫描：性能、可靠性、可维护性、复杂度
  3. 历史扫描：同类失败、换皮重来、历史教训
  4. 动机扫描：动机如何扭曲判断、认知陷阱
- 纪律：
  - 四小节共享同一债区。
  - 只保留各维度最致命且未被解剖层覆盖的弱点。
  - 输出一份“全弱点清单”，按确定性/严重性/可攻击性排序，去重后最多 10 条。
- 输出顶部必须有【摘要】块（3-5 行）。

## 7. `aolun-fileflow` 调整

- 默认步骤表改为：
  - `01-dissect`
  - `02-scan`
  - `03-other-mountains`（可选）
  - `04-attack`
  - `99-final`
- 不再为四层/四维分别建文件。
- 派发 subagent 时只传路径 + 五段式任务卡，不传原文内容。
- 债区继续使用“登记不删行 + 同源 #N 去重”。

## 8. checkpoint 规则（对齐 enloom v1.2）

1. checkpoint = 阶段结束，不是暂停等待。
2. 主窗口汇报后，不再派下一步。
3. 用户没明确回复“继续/调整/停止”前，什么也不做；沉默 ≠ 授权。
4. 汇报用“人话汇报”：目标/已完成/当前位置/发现与债/需要你决定/我的建议。
5. 无人托管仅在用户明确授权时连续推进，越过授权边界仍停。

## 9. 归档策略

- 在 repo 中新增 `skills/_archive/`，将 9 个旧分析 skill 整目录移入。
- 归档目录内文件正文不改，仅移动位置，保留 git 历史。
- 本地 `~/.aolun_skill/.agents/skills/` 同步移除这些 skill 的默认入口；如用户需要单维深挖，再从归档手动取用。

## 10. 实施步骤

1. 新建 `aolun-dissect` SKILL.md（合并四层核心检查项）。
2. 新建 `aolun-scan` SKILL.md（合并四维核心检查项）。
3. 重写 `aolun-fileflow` 的步骤表、暂停节点、任务卡模板。
4. 更新 `aolun-arming` 的路由：默认指向新 `aolun-dissect` / `aolun-scan`。
5. 弱化 `aolun-workflows`：将预设菜单并入 fileflow/arming，原 skill 标记为参考。
6. 归档 9 个旧分析 skill。
7. 更新 repo README/AGENTS 与本地安装副本。
8. 用 `guangzhou-state-capital-token` 重跑默认等人测试，验证：
   - 不再出现大段重复结论
   - 债区重复条目显著减少
   - 汇报更短、可一屏读完
9. 提交 repo commit。

## 11. 验收测试

- 用同一篇文章重跑 Workflow 2。
- 通过标准：
  - 01-dissect.md 和 02-scan.md 中同一论据不重复出现 2 次以上。
  - 债区不出现语义重复的新编号。
  - 解剖/扫描两次 checkpoint 的人话汇报均能一屏读完。
  - 攻击文可直接引用 01/02 中的唯一性结论，不需要跨多个文件拼凑。

## 12. 风险与决策记录

- 风险：合并后单文件可能变长，subagent 单次输出压力增大。
  - 缓解：控制“增量发现”纪律；若超长，允许拆成两个内部子任务但共享同一输出文件。
- 风险：归档后单维深挖入口变深。
  - 缓解：在新 `aolun-scan` 中保留“单维模式”，只跑某一节。
- 决策：不采用单 skill 全合并，保留 `aolun-attack` / `aolun-build` / `aolun-ground` 等不同目标 skill，避免把不同用途塞进一个巨型 skill。
