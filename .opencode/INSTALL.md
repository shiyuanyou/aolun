# Installing aolun for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add aolun to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
	"plugin": ["aolun@git+https://github.com/shiyuanyou/aolun.git"]
}
```

Restart OpenCode. That's it - the plugin auto-installs and registers all skills.

Verify by asking: "你现在有哪些批判超能力？"

## Migrating from the old manual-load install

If you previously installed aolun using manual skill loading or old symlink-based setup, clean up first:

```bash
# Remove old plugin symlink (if any)
rm -f ~/.config/opencode/plugins/aolun.js

# Remove old local clone install (optional)
rm -rf ~/.config/opencode/aolun

# Remove skills.paths entries that point to aolun if you added them manually
```

Then follow the installation steps above.

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load arming-liao
use skill tool to load attack-writer
```

Note: For maximum compatibility, the current plugin does not inject bootstrap text automatically.
Load `arming-liao` manually at the beginning of a new task/session.

## Updating

aolun updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
	"plugin": ["aolun@git+https://github.com/shiyuanyou/aolun.git#v1.0.1"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -Ei "aolun|plugin"`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)
3. Each skill directory must contain a valid `SKILL.md` frontmatter

### Tool mapping

When skills reference Claude-style tools:
- `TodoWrite` -> `todowrite`
- `Task` with subagents -> OpenCode `@mention` system
- `Skill` tool -> OpenCode native `skill` tool
- File operations -> your native OpenCode tools

## Getting Help

- Issues: https://github.com/shiyuanyou/aolun/issues
- Repository: https://github.com/shiyuanyou/aolun
