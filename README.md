# liao-skill —— 武装 AI 的工程批判大脑

> "我李敖批评人，是有凭据的。我的批评一剑封喉，因为我把他们的底裤都翻出来了。"

**你的 AI 不应该是一个点头称是的工具。它应该是一个能把任何技术论断拆底朝天、然后指出更好方向的批判者。**

「liao-skill」是一个 AI Agent Skills 合集，从李敖的思想气质和批判方法中提炼出一套完整的工程拆解方法论：四层解剖框架 + 四维弱点扫描 + 跨领域解法引擎 + 李敖风格战斗文本生成器。

不是风格模仿，是真正有杀伤力的工程判断。

---

## 为什么需要这个？

当前的 AI 在面对技术帖子时有一个根本问题：**它们会总结，但不会批判。**

- 拿到一篇吹捧微服务的帖子，给你列优缺点
- 拿到一个新材料的宣传，告诉你"有潜力"
- 拿到一个架构方案，说"这取决于具体情况"

李敖绝不这样做。李敖的方法是：

1. **先把定义要清楚**——你说的这个东西究竟是什么？
2. **再把机制拆干净**——它声称通过什么原理实现？
3. **然后把约束摆出来**——在什么条件下才成立？
4. **最后问谁在推它**——他们得什么好处？

四层全部暴露，再找弱点，再找更好的解法，最后用李敖的腔调一刀封喉。

---

## 武器结构

```
总入口
  arming-liao（路由 + 总原则）

第一层：解剖武器
  dissector-concept    概念层解剖器
  dissector-mechanism  机制层解剖器
  dissector-constraint 约束层解剖器
  dissector-interest   利益层解剖器

第二层：弱点扫描器
  scanner-logic        逻辑弱点扫描
  scanner-engineering  工程弱点扫描（计算机/建筑/机械/自动化/产品设计）
  scanner-history      历史弱点扫描
  scanner-motive       动机弱点扫描

第三层：重建武器
  other-mountains      跨领域解法引擎

第四层：输出武器
  attack-writer        李敖风格战斗文本生成器

编排层
  workflows            三条标准工作流
```

---

## 工程领域覆盖

- **计算机工程**：软件架构、系统设计、算法、基础设施、AI/ML
- **建筑与土木**：结构体系、材料、施工工艺、城市规划
- **机械工程**：动力系统、传动机构、制造工艺、可靠性
- **自动化与控制**：控制系统、传感器、执行器、工业协议
- **产品设计**：人机工程、材料选择、制造可行性、生命周期

---

## 可用命令

```
/dissect-concept      概念层解剖
/dissect-mechanism    机制层解剖
/dissect-constraint   约束层解剖
/dissect-interest     利益层解剖
/scan-logic           逻辑弱点扫描
/scan-engineering     工程弱点扫描
/scan-history         历史弱点扫描
/scan-motive          动机弱点扫描
/other-mountains      跨领域解法引擎
/attack               李敖风格攻击文
/quick-shot           快速狙击（Workflow 1）
/full-teardown        底朝天全拆（Workflow 3）
```

---

## 安装

### Claude Code

```bash
git clone https://github.com/YOUR_USERNAME/liao-skill
cd liao-skill
claude --plugin-dir .
```

验证：
```bash
bash tests/validate.sh
```

### OpenCode

参考 [`.opencode/INSTALL.md`](.opencode/INSTALL.md)

### Codex

参考 [`.codex/INSTALL.md`](.codex/INSTALL.md)

### Cursor

克隆仓库后将项目目录注册到 Cursor 的插件路径。

### 通用

将 `skills/arming-liao/SKILL.md` 作为 system prompt 注入，然后按需加载其他 skill 文件。

---

## 三条工作流

| 工作流 | 适用场景 | 时间预算 |
|-------|---------|---------|
| Workflow 1：快速狙击 | 推文/短帖，快速回应 | 5-10 分钟 |
| Workflow 2：标准拆解 | 完整技术文章或方案 | 30-60 分钟 |
| Workflow 3：底朝天全拆 | 重要行业论断或主流方法论 | 1-3 小时 |

---

## 这不是什么

- **不是风格模仿器。** 不是把 AI 训练成说话像李敖。是把李敖的批判方法论系统化。
- **不是只会破坏的虚无主义。** 每次拆解都必须给出更好的方向——他山之石引擎负责这件事。
- **不是阴谋论工具。** 动机扫描是认知科学，不是道德审判。

---

## 验证安装

**macOS / Linux：**
```bash
bash tests/validate.sh
```

**Windows：**
```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/validate.ps1
```

---

## 许可证

MIT License
