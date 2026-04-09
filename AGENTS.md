# AGENTS.md — aolun (敖论)

## What this repo is

A multi-platform skill plugin that equips AI agents with a systematic critical-thinking methodology. Skills dissect technical claims through four layers (concept → mechanism → constraint → interest), scan for weaknesses, pull cross-domain solutions, and generate Li Ao–style attack prose.

## Repository structure

| Path | Purpose |
|------|---------|
| `skills/*/SKILL.md` | Core skill definitions (12 skills). Each has YAML frontmatter (`name`, `description`) followed by markdown body. Names use `aolun-` prefix for entry skills and `aolun-inter-` prefix for internal pipeline skills. |
| `commands/*.md` | Slash-command definitions for Claude Code / Cursor. Also have frontmatter. |
| `hooks/` | Session-start hook that injects `aolun-arming` bootstrap into new conversations. |
| `.opencode/plugins/aolun.js` | OpenCode plugin: registers skills path and injects bootstrap into first user message. |
| `.claude-plugin/plugin.json` | Claude Code plugin manifest. |
| `.cursor-plugin/plugin.json` | Cursor plugin manifest. |
| `.codex/INSTALL.md` | Codex manual install instructions. |
| `tests/validate.sh` / `validate.ps1` | Validation: checks JSON, required files, frontmatter, and hook executability. |

## Key conventions

- **SKILL.md frontmatter is required.** Every `skills/*/SKILL.md` and `commands/*.md` must start with `---` frontmatter containing `name:` and `description:`.
- **Frontmatter must be stripped before use.** The OpenCode plugin (`aolun.js`) strips frontmatter via regex; the session-start hook does not strip it (the receiving platform handles that). If you add a new skill, ensure your frontmatter parsing matches the existing pattern.
- **Skills are pure Markdown instruction sets.** They contain no executable code — they are loaded and interpreted by the host agent.

## Skill dependency chain

Skills are not independent. The required invocation order is:

```
aolun-arming (router, session bootstrap) ⚡入口
  → aolun-dissect-concept → aolun-inter-dissect-mechanism → aolun-inter-dissect-constraint → aolun-inter-dissect-interest
  → aolun-scan-logic / aolun-scan-engineering / aolun-scan-history / aolun-scan-motive
  → aolun-other-mountains
  → aolun-attack
```

Dissectors must run in order. Scanners can run in parallel after dissection. Attack-writer runs last.

## Running validation

```bash
npm test
# or directly:
bash tests/validate.sh
```

On Windows:
```powershell
npm run test:win
```

Validation checks: JSON validity of config files, presence of all required files, YAML frontmatter in every SKILL.md and command file, and that `hooks/session-start` is executable.

## When editing skills

- Preserve the `---` frontmatter block with `name` and `description` fields at the top of every SKILL.md.
- The `description` field is the skill's trigger description — it must clearly state when the skill should activate.
- After editing, run `npm test` to validate.
- Skill content is bilingual (Chinese primary, English secondary). Maintain both unless intentionally removing one.

## Multi-platform install

- **Claude Code**: `claude --plugin-dir .`
- **OpenCode**: add `"aolun@git+https://github.com/shiyuanyou/aolun.git"` to `opencode.json` plugin array
- **Cursor/Codex**: see `.cursor-plugin/` and `.codex/INSTALL.md`

## Gotchas

- `hooks/session-start` must be `chmod +x` — the validation script checks this.
- The OpenCode plugin path (`../../skills`) is relative to `.opencode/plugins/aolun.js`. Moving the plugin file breaks skill discovery.
- The skill injector in `aolun.js` prepends bootstrap to the first user message part — it does not replace it. This means the bootstrap content appears every new session automatically on OpenCode.