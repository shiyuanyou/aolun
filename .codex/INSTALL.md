# liao-skill for Codex

按下面步骤接入：

1. 确认仓库已克隆到本地。
2. 新会话开始时先读取 `skills/arming-liao/SKILL.md`，作为路由和方法论约束。
3. 针对具体任务，按需读取下列文件：
   - `skills/dissector-concept/SKILL.md`
   - `skills/dissector-mechanism/SKILL.md`
   - `skills/dissector-constraint/SKILL.md`
   - `skills/dissector-interest/SKILL.md`
   - `skills/scanner-logic/SKILL.md`
   - `skills/scanner-engineering/SKILL.md`
   - `skills/scanner-history/SKILL.md`
   - `skills/scanner-motive/SKILL.md`
   - `skills/other-mountains/SKILL.md`
   - `skills/attack-writer/SKILL.md`
   - `skills/workflows/SKILL.md`
4. 如果宿主支持 Markdown commands，可额外加载 `commands/` 目录；不支持时直接读取同名命令文件内容。

完成后，手动验证：
- 会话起始时能够成功读取 `arming-liao`
- 拿到目标帖子后，能够按工作流序列调用各 skill
