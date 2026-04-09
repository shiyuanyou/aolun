[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = 0

function Fail([string]$msg) {
    Write-Error "FAIL: $msg"
    $script:errors++
}

function Read-JsonFile([string]$Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
}

function Get-FrontMatter([string]$Path) {
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    if ($lines.Count -eq 0) { throw "Empty file: $Path" }
    if ($lines[0] -ne "---") { throw "Missing frontmatter: $Path" }
    $termIdx = [Array]::IndexOf($lines, "---", 1)
    if ($termIdx -lt 1) { throw "Missing frontmatter terminator: $Path" }
    $fm = ($lines[1..($termIdx - 1)] -join "`n")
    if (-not ($fm -match '(?m)^name:\s*.+$')) { throw "Missing 'name' in frontmatter: $Path" }
    if (-not ($fm -match '(?m)^description:')) { throw "Missing 'description' in frontmatter: $Path" }
}

Write-Host "Validating JSON files..."
foreach ($f in @(".claude-plugin/plugin.json", ".cursor-plugin/plugin.json", "hooks/hooks.json", "package.json")) {
    $path = Join-Path $repoRoot $f
    if (-not (Test-Path -LiteralPath $path)) { Fail "Missing JSON file: $f" }
    else { try { Read-JsonFile -Path $path } catch { Fail "Invalid JSON: $f" } }
}

Write-Host "Validating required files..."
$required = @(
    "hooks/session-start", "hooks/session-start.ps1", "hooks/run-hook.cmd",
    "skills/arming-liao/SKILL.md",
    "skills/dissector-concept/SKILL.md", "skills/dissector-mechanism/SKILL.md",
    "skills/dissector-constraint/SKILL.md", "skills/dissector-interest/SKILL.md",
    "skills/scanner-logic/SKILL.md", "skills/scanner-engineering/SKILL.md",
    "skills/scanner-history/SKILL.md", "skills/scanner-motive/SKILL.md",
    "skills/other-mountains/SKILL.md", "skills/attack-writer/SKILL.md",
    "skills/workflows/SKILL.md",
    ".codex/INSTALL.md", ".opencode/INSTALL.md"
)
foreach ($f in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $f))) { Fail "Missing required file: $f" }
}

Write-Host "Validating frontmatter in SKILL.md files..."
Get-ChildItem -Path (Join-Path $repoRoot "skills") -Recurse -Filter "SKILL.md" | ForEach-Object {
    try { Get-FrontMatter -Path $_.FullName }
    catch { Fail $_.Exception.Message }
}

Write-Host "Validating command files..."
Get-ChildItem -Path (Join-Path $repoRoot "commands") -Filter "*.md" | ForEach-Object {
    try { Get-FrontMatter -Path $_.FullName }
    catch { Fail $_.Exception.Message }
}

if ($script:errors -eq 0) {
    Write-Host ""
    Write-Host "All checks passed. aolun is ready."
} else {
    Write-Host ""
    Write-Error "Found $($script:errors) error(s). Please fix them before using aolun."
    exit 1
}
