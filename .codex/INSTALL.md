# aolun for Codex

按下面步骤接入：

1. 确认仓库已克隆到本地。
2. 新会话开始时先读取 `skills/aolun-arming/SKILL.md`，作为路由和方法论约束。
3. 针对具体任务，按需读取下列文件：
   - `skills/aolun-dissect/SKILL.md`
   - `skills/aolun-scan/SKILL.md`
   - `skills/aolun-other-mountains/SKILL.md`
   - `skills/aolun-attack/SKILL.md`
   - `skills/aolun-build/SKILL.md`
   - `skills/aolun-ground/SKILL.md`
   - `skills/aolun-fileflow/SKILL.md`
   - `skills/aolun-prepare-docs/SKILL.md`
4. 如果宿主支持 Markdown commands，可额外加载 `commands/` 目录；不支持时直接读取同名命令文件内容。

完成后，手动验证：
- 会话起始时能够成功读取 `aolun-arming`
- 拿到目标帖子后，能够按工作流序列调用各 skill