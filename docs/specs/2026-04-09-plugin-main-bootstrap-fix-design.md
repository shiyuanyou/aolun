# Design: Fix Plugin Loading — Add `main` Entry + Bootstrap Injection

**Date:** 2026-04-09  
**Status:** Approved

---

## Problem

aolun fails to load as an OpenCode plugin for two reasons:

1. **Missing `main` field in `package.json`** — OpenCode's Bun runtime resolves plugin entry via the `main` field. Without it, the module cannot be found and the plugin silently fails to load. Error seen in logs: `Cannot find module '.../node_modules/aolun'`.

2. **No bootstrap injection** — The plugin registers the skills path but does not inject `arming-liao` context at session start. Users must manually load the skill each session, which is friction and inconsistent with the intended usage model.

---

## Solution

Align aolun with the superpowers plugin pattern, which is verified to work.

### File 1: `package.json`

Add `"main"` field pointing to the plugin entry:

```json
{
  "name": "aolun",
  "version": "1.0.2",
  "main": ".opencode/plugins/aolun.js",
  "type": "module",
  ...
}
```

Version bumped to `1.0.2` (bug fix release).

### File 2: `.opencode/plugins/aolun.js`

Rewrite to match superpowers plugin structure:

**`config` hook** (existing, preserved):
- Adds `skills/` directory to `config.skills.paths` so OpenCode discovers all aolun skills.

**`experimental.chat.messages.transform` hook** (new):
- Reads `skills/arming-liao/SKILL.md` at runtime.
- Strips YAML frontmatter (lines between `---` delimiters).
- Finds the first `role === 'user'` message in `output.messages`.
- Checks for de-duplication marker: if the message already contains `AOLUN_BOOTSTRAP`, skip injection.
- Prepends the arming-liao content wrapped in `<AOLUN_BOOTSTRAP>...</AOLUN_BOOTSTRAP>` tags to the first user message's parts array.

**Bootstrap wrapper format:**
```
<AOLUN_BOOTSTRAP>
{arming-liao SKILL.md body, frontmatter stripped}
</AOLUN_BOOTSTRAP>
```

The `AOLUN_BOOTSTRAP` tag (not `EXTREMELY_IMPORTANT`) is used to:
- Avoid namespace collision with superpowers bootstrap
- Enable precise de-duplication checks

**Exports** (unchanged):
```js
export const AolunPlugin = createPlugin;
export default createPlugin;
```

---

## Architecture

```
opencode.json
  └── plugin: aolun@git+...
        └── package.json ["main"] → .opencode/plugins/aolun.js
              ├── config hook
              │     └── config.skills.paths.push(skills/)
              └── experimental.chat.messages.transform hook
                    └── reads skills/arming-liao/SKILL.md
                          └── injects into first user message (once per session)
```

---

## Error Handling

- If `arming-liao/SKILL.md` does not exist, skip bootstrap injection silently (no crash).
- If `output.messages` is empty or has no user message, skip silently.
- De-duplication guard prevents double injection across multiple transform calls.

---

## What Does Not Change

- All 12 skills remain unchanged.
- `skills/` directory structure unchanged.
- Plugin export names unchanged (`AolunPlugin`, `default`).
- No new dependencies introduced.

---

## Files Changed

| File | Change |
|------|--------|
| `package.json` | Add `"main"`, bump version to `1.0.2` |
| `.opencode/plugins/aolun.js` | Rewrite: add `experimental.chat.messages.transform`, align function signature |
