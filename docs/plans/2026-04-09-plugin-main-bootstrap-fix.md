# Plugin Main Field + Bootstrap Injection Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix aolun plugin loading by adding the missing `main` field to `package.json` and implementing bootstrap injection of `arming-liao` into the first user message of each session.

**Architecture:** Two-file change. `package.json` gains a `main` entry so OpenCode's Bun runtime can locate the plugin. `aolun.js` is rewritten to align with the verified superpowers pattern: a `config` hook registers the skills path, and a `experimental.chat.messages.transform` hook injects `arming-liao` content into the first user message once per session.

**Tech Stack:** Node.js ESM, OpenCode plugin API (`@opencode-ai/plugin`), Bun runtime

---

## File Map

| File | Action |
|------|--------|
| `package.json` | Modify: add `"main"` field, bump version to `1.0.2` |
| `.opencode/plugins/aolun.js` | Modify: rewrite to add bootstrap injection hook |

---

### Task 1: Add `main` field to `package.json`

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Open and edit `package.json`**

Replace the current contents with:

```json
{
  "name": "aolun",
  "version": "1.0.2",
  "description": "武装 AI 工程批判大脑的 Skills 合集——四层解剖 × 四维扫描 × 跨域重建 × 辩证驱动的战斗文本生成",
  "main": ".opencode/plugins/aolun.js",
  "license": "MIT",
  "type": "module",
  "scripts": {
    "validate": "bash tests/validate.sh",
    "validate:win": "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/validate.ps1",
    "test": "bash tests/validate.sh",
    "test:win": "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/validate.ps1"
  }
}
```

- [ ] **Step 2: Verify the file is valid JSON**

```bash
node -e "require('./package.json'); console.log('OK')"
```

Expected output: `OK`

- [ ] **Step 3: Commit**

```bash
git add package.json
git commit -m "fix: add main field to package.json to fix plugin loading"
```

---

### Task 2: Rewrite `.opencode/plugins/aolun.js` with bootstrap injection

**Files:**
- Modify: `.opencode/plugins/aolun.js`

- [ ] **Step 1: Rewrite the plugin file**

Replace the entire contents of `.opencode/plugins/aolun.js` with:

```js
/**
 * aolun plugin for OpenCode.ai
 *
 * Registers aolun skills directory for OpenCode discovery.
 * Injects arming-liao bootstrap into the first user message of each session.
 */

import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const extractAndStripFrontmatter = (content) => {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, content };
  return { frontmatter: {}, content: match[2] };
};

const normalizePath = (p, homeDir) => {
  if (!p || typeof p !== 'string') return null;
  let normalized = p.trim();
  if (!normalized) return null;
  if (normalized.startsWith('~/')) {
    normalized = path.join(homeDir, normalized.slice(2));
  } else if (normalized === '~') {
    normalized = homeDir;
  }
  return path.resolve(normalized);
};

export const AolunPlugin = async ({ client, directory }) => {
  const homeDir = os.homedir();
  const skillsDir = path.resolve(__dirname, '../../skills');
  const envConfigDir = normalizePath(process.env.OPENCODE_CONFIG_DIR, homeDir);
  const configDir = envConfigDir || path.join(homeDir, '.config/opencode');

  const getBootstrapContent = () => {
    const skillPath = path.join(skillsDir, 'arming-liao', 'SKILL.md');
    if (!fs.existsSync(skillPath)) return null;
    const fullContent = fs.readFileSync(skillPath, 'utf8');
    const { content } = extractAndStripFrontmatter(fullContent);
    return `<AOLUN_BOOTSTRAP>\n${content}\n</AOLUN_BOOTSTRAP>`;
  };

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
      const localSkillPath = path.join(configDir, 'skills');
      if (!config.skills.paths.includes(localSkillPath)) {
        config.skills.paths.push(localSkillPath);
      }
    },

    'experimental.chat.messages.transform': async (_input, output) => {
      const bootstrap = getBootstrapContent();
      if (!bootstrap || !output.messages.length) return;
      const firstUser = output.messages.find(m => m.info.role === 'user');
      if (!firstUser || !firstUser.parts.length) return;
      if (firstUser.parts.some(p => p.type === 'text' && p.text.includes('AOLUN_BOOTSTRAP'))) return;
      const ref = firstUser.parts[0];
      firstUser.parts.unshift({ ...ref, type: 'text', text: bootstrap });
    }
  };
};

export default AolunPlugin;
```

- [ ] **Step 2: Verify the file is valid ESM**

```bash
node --input-type=module <<'EOF'
import { fileURLToPath } from 'url';
import path from 'path';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
console.log('ESM parse OK');
EOF
```

Expected output: `ESM parse OK`

- [ ] **Step 3: Commit**

```bash
git add .opencode/plugins/aolun.js
git commit -m "feat: add bootstrap injection hook, align plugin with superpowers pattern"
```

---

### Task 3: Verify end-to-end with OpenCode logs

**Files:** none (verification only)

- [ ] **Step 1: Clear the aolun cache to force a clean re-install**

```bash
rm -rf ~/.cache/opencode/packages/aolun@git+https:/github.com/shiyuanyou/aolun.git
```

- [ ] **Step 2: Push changes to GitHub**

```bash
git push origin main
```

- [ ] **Step 3: Run OpenCode with log output and check for errors**

```bash
opencode run --print-logs "hello" 2>&1 | grep -iE "aolun|plugin|bootstrap|error|failed"
```

Expected: lines showing plugin loading without ERROR, e.g.:
```
INFO  service=plugin path=aolun@git+... loading plugin
INFO  service=npm pkg=aolun@git+... installing package
```

No `ERROR` or `failed to load plugin` lines.

- [ ] **Step 4: Verify skills are discovered**

```bash
opencode run --print-logs "list all skills" 2>&1 | grep -i "arming-liao"
```

Expected: skill discovery log or skill listed in output.

---

### Task 4: Update cache patch (temporary local fix cleanup)

**Files:** none (clean up earlier workaround)

- [ ] **Step 1: Verify the cache was re-installed with the new `package.json`**

```bash
cat ~/.cache/opencode/packages/aolun@git+https:/github.com/shiyuanyou/aolun.git/node_modules/aolun/package.json | grep main
```

Expected output:
```
"main": ".opencode/plugins/aolun.js",
```

This confirms the temporary patch we applied earlier is now part of the canonical source and no longer needs manual maintenance.
