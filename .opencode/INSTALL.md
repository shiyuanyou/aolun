# Installing aolun for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

1. Clone aolun to a local directory:

```bash
git clone https://github.com/shiyuanyou/aolun.git ~/git-repos/aolun
```

2. Add the skills path to your `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": ["~/git-repos/aolun/skills"]
  }
}
```

That's it. No npm install, no plugin loading, no network requests on startup.

Verify by asking: "你现在有哪些批判超能力？"

## Migrating from the old JS plugin install

If you previously used the `plugin` array:

```bash
# Remove old plugin config — replace with skills.paths (see above)
# Delete old node_modules
rm -rf ~/git-repos/aolun/.opencode/node_modules
rm -rf ~/.config/opencode/node_modules
```

## Usage

Use OpenCode's native `skill` tool to load aolun skills:

```
use skill tool to load aolun-arming
use skill tool to load aolun-attack
```

## Updating

```bash
cd ~/git-repos/aolun && git pull
```

Updates take effect on next session. No restart needed if you're already in a session.

## Troubleshooting

### Skills not found

1. Run `opencode debug skill` to list discovered skills
2. Verify the `skills.paths` entry points to the correct directory
3. Each skill directory must contain a valid `SKILL.md` with frontmatter (`name` + `description`)

### Tool mapping

When skills reference Claude-style tools:
- `TodoWrite` -> `todowrite`
- `Task` with subagents -> OpenCode `@mention` system
- `Skill` tool -> OpenCode native `skill` tool
- File operations -> your native OpenCode tools

## Getting Help

- Issues: https://github.com/shiyuanyou/aolun/issues
- Repository: https://github.com/shiyuanyou/aolun
