#!/usr/bin/env bash
set -euo pipefail

# setup-qwen.sh — One-click verification for Qwen Code users
# Checks Qwen CLI, all .qwen/ files, and dependencies

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ANSI colors (only on TTY)
isTTY=${isTTY:-false}
if [ -t 1 ]; then isTTY=true; fi

green() { if $isTTY; then printf '\033[32m%s\033[0m\n' "$1"; else echo "$1"; fi; }
red()   { if $isTTY; then printf '\033[31m%s\033[0m\n' "$1"; else echo "$1"; fi; }
dim()   { if $isTTY; then printf '\033[2m%s\033[0m\n' "$1"; else echo "$1"; fi; }
yellow() { if $isTTY; then printf '\033[33m%s\033[0m\n' "$1"; else echo "$1"; fi; }

pass_count=0
fail_count=0
warn_count=0

pass() { green "  ✓ $1"; ((pass_count++)); }
fail() { red "  ✗ $1"; ((fail_count++)); }
warn() { yellow "  ⚠ $1"; ((warn_count++)); }

echo ""
echo "career-ops — Qwen Code Setup Check"
echo "==================================="
echo ""

# 1. Qwen CLI
echo "1. AI CLI availability"
if command -v qwen &>/dev/null; then
  qwen_version=$(qwen --version 2>/dev/null || echo "unknown")
  pass "qwen CLI found ($qwen_version)"
else
  warn "qwen CLI not found (install Qwen Code for native support)"
fi

if command -v claude &>/dev/null; then
  claude_version=$(claude --version 2>/dev/null || echo "unknown")
  pass "claude CLI found ($claude_version)"
else
  warn "claude CLI not found (optional, only needed for Claude Code)"
fi

if ! command -v qwen &>/dev/null && ! command -v claude &>/dev/null; then
  fail "No AI CLI found — install qwen or claude to use career-ops"
fi

# 2. Qwen skill files
echo ""
echo "2. Qwen skill files"

qwen_files=(
  ".qwen/settings.json"
  ".qwen/skills/career-ops/skill.md"
  ".qwen/commands/career-ops.md"
)

for f in "${qwen_files[@]}"; do
  if [[ -f "$f" ]]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# 3. Shared files
echo ""
echo "3. Shared platform files"

shared_files=(
  "QWEN.md"
  "CLAUDE.md"
  "modes/_shared.md"
  "modes/_profile.template.md"
  "cv.md"
  "config/profile.yml"
)

for f in "${shared_files[@]}"; do
  if [[ -f "$f" ]]; then
    pass "$f exists"
  else
    warn "$f missing (will be created during onboarding)"
  fi
done

# 4. Dependencies
echo ""
echo "4. Dependencies"

if [[ -d "node_modules" ]]; then
  pass "npm dependencies installed"
else
  fail "node_modules missing — run: npm install"
fi

if command -v node &>/dev/null; then
  node_version=$(node --version)
  major=$(echo "$node_version" | cut -d. -f1 | tr -d 'v')
  if (( major >= 18 )); then
    pass "Node.js $node_version (>= 18)"
  else
    fail "Node.js $node_version (need >= 18)"
  fi
else
  fail "Node.js not found"
fi

if npx playwright install --dry-run 2>/dev/null || [ -d "$(echo ~/.cache/ms-playwright 2>/dev/null)" ]; then
  pass "Playwright browser cache found"
else
  warn "Playwright browsers may not be installed — run: npx playwright install chromium"
fi

# 5. Data directories
echo ""
echo "5. Data directories"

for dir in data output reports jds batch/logs batch/tracker-additions; do
  if [[ -d "$dir" ]]; then
    pass "$dir/ exists"
  else
    mkdir -p "$dir"
    pass "$dir/ created"
  fi
done

# Summary
echo ""
echo "=============================="
echo "Results: $pass_count passed, $fail_count failed, $warn_count warnings"
echo ""

if (( fail_count > 0 )); then
  red "Setup incomplete. Fix the issues above and run this script again."
  echo ""
  echo "Quick fixes:"
  echo "  npm install              # Install dependencies"
  echo "  npx playwright install chromium  # Install browser for PDF/scraping"
  echo ""
  exit 1
else
  green "All checks passed! You're ready to use career-ops with Qwen Code."
  echo ""
  echo "Get started:"
  echo "  qwen                     # Start Qwen Code in this directory"
  echo "  /career-ops              # Show available commands"
  echo "  /career-ops {JD URL}     # Evaluate a job description"
  echo ""
  echo "Join the community: https://discord.gg/8pRpHETxa4"
  exit 0
fi
