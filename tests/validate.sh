#!/usr/bin/env bash
# macOS / Linux 验证脚本
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

fail() {
  echo "FAIL: $1" >&2
  ERRORS=$((ERRORS + 1))
}

echo "Validating JSON files..."
for f in \
  .claude-plugin/plugin.json \
  .cursor-plugin/plugin.json \
  hooks/hooks.json \
  package.json
do
  path="$REPO_ROOT/$f"
  if [ ! -f "$path" ]; then
    fail "Missing JSON file: $f"
  elif ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$path" 2>/dev/null; then
    fail "Invalid JSON: $f"
  fi
done

echo "Validating required files..."
for f in \
  hooks/session-start \
  hooks/session-start.ps1 \
  hooks/run-hook.cmd \
  skills/aolun-arming/SKILL.md \
  skills/aolun-dissect-concept/SKILL.md \
  skills/aolun-inter-dissect-mechanism/SKILL.md \
  skills/aolun-inter-dissect-constraint/SKILL.md \
  skills/aolun-inter-dissect-interest/SKILL.md \
  skills/aolun-scan-logic/SKILL.md \
  skills/aolun-scan-engineering/SKILL.md \
  skills/aolun-scan-history/SKILL.md \
  skills/aolun-scan-motive/SKILL.md \
  skills/aolun-other-mountains/SKILL.md \
  skills/aolun-attack/SKILL.md \
  skills/aolun-workflows/SKILL.md \
  skills/aolun-ground/SKILL.md \
  skills/aolun-build/SKILL.md \
  skills/aolun-fileflow/SKILL.md \
  skills/aolun-scan-orchestrator/SKILL.md \
  skills/aolun-prepare-docs/SKILL.md \
  .codex/INSTALL.md \
  .opencode/INSTALL.md
do
  [ -f "$REPO_ROOT/$f" ] || fail "Missing required file: $f"
done

echo "Validating frontmatter in SKILL.md files..."
check_frontmatter() {
  local file="$1"
  local first_line
  first_line=$(head -1 "$file" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//')
  if [ "$first_line" != "---" ]; then
    fail "Missing frontmatter: $file"; return
  fi
  local terminator
  terminator=$(tail -n +2 "$file" | grep -n '^---$' | head -1 | cut -d: -f1)
  if [ -z "$terminator" ]; then
    fail "Missing frontmatter terminator: $file"; return
  fi
  local fm
  fm=$(sed -n "2,$((terminator))p" "$file")
  echo "$fm" | grep -q '^name:' || fail "Missing 'name' in frontmatter: $file"
  echo "$fm" | grep -q '^description:' || fail "Missing 'description' in frontmatter: $file"
}

for skill_file in "$REPO_ROOT"/skills/*/SKILL.md; do
  check_frontmatter "$skill_file"
done

echo "Validating command files..."
for cmd_file in "$REPO_ROOT"/commands/*.md; do
  check_frontmatter "$cmd_file"
done

echo "Checking hooks are executable..."
[ -x "$REPO_ROOT/hooks/session-start" ] || fail "hooks/session-start is not executable"

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "All checks passed. aolun is ready."
else
  echo ""
  echo "Found $ERRORS error(s). Please fix them before using aolun." >&2
  exit 1
fi
