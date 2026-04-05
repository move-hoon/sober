#!/bin/bash
# Claude Pro MinMax - Installation Script
set -e

# Error handler: print failure line and exit message
_on_error() { echo ""; echo "❌ Installation failed at line $1. Check output above."; }
trap '_on_error $LINENO' ERR

# Guard unsupported invocations (`curl | bash`, process substitution)
if [[ -z "${BASH_SOURCE[0]}" || "${BASH_SOURCE[0]}" == "bash" ]]; then
  echo "❌ This script cannot be run via 'curl | bash'."
  echo "   Please clone the repository first:"
  echo "   git clone https://github.com/move-hoon/claude-pro-minmax.git && cd claude-pro-minmax && bash install.sh"
  exit 1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -f "$SCRIPT_DIR/.claude/CLAUDE.md" ] || [ ! -f "$SCRIPT_DIR/package.json" ]; then
  echo "❌ This script must be run from a cloned CPMM repository directory."
  echo "   Please run:"
  echo "   git clone https://github.com/move-hoon/claude-pro-minmax.git && cd claude-pro-minmax && bash install.sh"
  exit 1
fi

# Marker-based detection for Install vs Update
CPMM_MARKER="$HOME/.claude/.cpmm-version"
IS_UPDATE=false
if [ -f "$CPMM_MARKER" ]; then IS_UPDATE=true; fi

# Legacy CPMM detection (marker was introduced after early releases)
LEGACY_CPMM=false
if [ "$IS_UPDATE" = false ] && [ -d "$HOME/.claude" ]; then
  if [ -f "$HOME/.claude/CLAUDE.md" ] &&
     [ -f "$HOME/.claude/settings.json" ] &&
     [ -f "$HOME/.claude/commands/do.md" ] &&
     [ -f "$HOME/.claude/commands/do-opus.md" ]; then
    LEGACY_CPMM=true
  fi
fi

# Header message: show Install vs Update mode
if [ "$IS_UPDATE" = true ]; then
  echo "🔄 Updating Claude Pro MinMax (CPMM)"
  INSTALLED_VERSION=$(head -1 "$CPMM_MARKER" 2>/dev/null || echo "unknown")
  echo "   Current version: $INSTALLED_VERSION"
else
  echo "🚀 Installing Claude Pro MinMax (CPMM)"
fi

# Backup existing ~/.claude (Fresh Install Only)
HAS_EXISTING_RTK_HOOK=false
if [ -f "$HOME/.claude/settings.json" ] && grep -q "rtk-rewrite.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  HAS_EXISTING_RTK_HOOK=true
fi

cleanup_managed_claude_json() {
  local target="$1"
  local status=0

  [ -f "$target" ] || return 0

  set +e
  node - "$target" <<'NODE'
const fs = require("node:fs");

const target = process.argv[2];
const data = JSON.parse(fs.readFileSync(target, "utf8"));
const servers = data && typeof data === "object" ? data.mcpServers : null;

if (servers && Object.prototype.hasOwnProperty.call(servers, "context7")) {
  delete servers.context7;
  fs.writeFileSync(target, `${JSON.stringify(data, null, 4)}\n`);
  process.exit(10);
}
NODE
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    return 0
  fi
  if [ "$status" -eq 10 ]; then
    echo "✅ Removed legacy Context7 MCP from ~/.claude.json"
    return 0
  fi

  return "$status"
}

user_mcp_contains_legacy_context7() {
  local target="$1"

  [ -f "$target" ] || return 1

  node - "$target" <<'NODE'
const fs = require("node:fs");

const target = process.argv[2];
const data = JSON.parse(fs.readFileSync(target, "utf8"));
const hasLegacyContext7 = Boolean(
  data &&
  typeof data === "object" &&
  data.mcpServers &&
  Object.prototype.hasOwnProperty.call(data.mcpServers, "context7")
);

process.exit(hasLegacyContext7 ? 0 : 1);
NODE
}

context7_cli_installed() {
  command -v ctx7 >/dev/null 2>&1
}

context7_global_bin_path() {
  if command -v ctx7 >/dev/null 2>&1; then
    command -v ctx7
    return 0
  fi

  if command -v npm >/dev/null 2>&1; then
    NPM_PREFIX=$(npm prefix -g 2>/dev/null || true)
    if [ -n "$NPM_PREFIX" ] && [ -x "$NPM_PREFIX/bin/ctx7" ]; then
      printf '%s\n' "$NPM_PREFIX/bin/ctx7"
      return 0
    fi
  fi

  return 1
}

context7_official_skill_installed() {
  [ -f "$HOME/.claude/skills/find-docs/SKILL.md" ]
}

context7_official_rule_installed() {
  [ -f "$HOME/.claude/rules/context7.md" ]
}

context7_official_integration_installed() {
  context7_official_skill_installed && context7_official_rule_installed
}

print_context7_manual_hints() {
  echo "   Re-run cpmm setup in an interactive terminal to opt in, or run the official commands directly:"
  echo "   npm install -g ctx7"
  echo "   ctx7 setup --cli --claude"
}

run_context7_global_install() {
  if ! command -v npm >/dev/null 2>&1; then
    echo "⚠️  Skipping Context7 global install (npm not found)."
    print_context7_manual_hints
    return 1
  fi

  echo ""
  echo "📚 Context7 CLI Global Install"
  echo "  $ npm install -g ctx7"

  if npm install -g ctx7; then
    CONTEXT7_BIN=$(context7_global_bin_path || true)
    if [ -n "${CONTEXT7_BIN:-}" ]; then
      echo "✅ Context7 CLI installed"
      CONTEXT7_VERSION=$("$CONTEXT7_BIN" --version 2>/dev/null | head -1 || true)
      [ -n "$CONTEXT7_VERSION" ] && echo "   Version: $CONTEXT7_VERSION"
      return 0
    fi

    echo "⚠️  Context7 CLI installed but is not visible on PATH in this shell."
    echo "   A later step will use the resolved global binary path directly."
    return 0
  fi

  echo "⚠️  Context7 global install did not complete."
  print_context7_manual_hints
  return 1
}

run_context7_official_setup() {
  if ! command -v npm >/dev/null 2>&1; then
    echo "⚠️  Skipping official Context7 setup (npm not found)."
    print_context7_manual_hints
    return 1
  fi

  if ! context7_global_bin_path >/dev/null 2>&1; then
    if ! run_context7_global_install; then
      return 1
    fi
  fi

  CONTEXT7_BIN=$(context7_global_bin_path || true)
  if [ -z "${CONTEXT7_BIN:-}" ]; then
    echo "⚠️  Context7 CLI binary could not be resolved after install."
    print_context7_manual_hints
    return 1
  fi

  echo ""
  echo "📚 Context7 Official CLI + Skills Setup"
  echo "   This runs the official Context7 Claude Code setup."
  echo "  $ $CONTEXT7_BIN setup --cli --claude"

  if "$CONTEXT7_BIN" setup --cli --claude; then
    echo "✅ Context7 official CLI + Skills setup complete"
    return 0
  fi

  echo "⚠️  Official Context7 setup did not complete."
  print_context7_manual_hints
  return 1
}

offer_context7_setup() {
  local choice="${CPMM_CONTEXT7_SETUP_CHOICE:-}"

  if context7_cli_installed && context7_official_integration_installed; then
    echo ""
    echo "📚 Context7 Setup"
    echo "   Context7 CLI and official Claude integration are already installed."
    return 0
  fi

  if [ -z "$choice" ] && [ ! -t 0 ]; then
    echo ""
    echo "📚 Context7 Setup (Optional)"
    echo "   Skipped in non-interactive mode."
    print_context7_manual_hints
    return 0
  fi

  case "$choice" in
    official-setup|skip) ;;
    *) choice="" ;;
  esac

  if [ -z "$choice" ]; then
    echo ""
    echo "📚 Context7 Setup (Optional)"
    echo "   Install ctx7 globally and run the official Context7 Claude Code setup?"
    echo "   1) Yes, run npm install -g ctx7 + ctx7 setup --cli --claude (Recommended)"
    echo "   2) Skip for now (default)"
    echo -n "   Select [1-2]: "
    read -r CONTEXT7_CHOICE < /dev/tty || CONTEXT7_CHOICE="3"

    case $CONTEXT7_CHOICE in
      1) choice="official-setup" ;;
      *) choice="skip" ;;
    esac
  fi

  case "$choice" in
    official-setup)
      run_context7_official_setup
      ;;
    *)
      echo ""
      echo "⚠️  Skipping Context7 setup for now."
      print_context7_manual_hints
      ;;
  esac
}

if [ "$IS_UPDATE" = false ] && [ -d "$HOME/.claude" ]; then
  if [ -d "$HOME/.claude.pre-cpmm" ]; then
    echo "⚠️  ~/.claude.pre-cpmm already exists, skipping backup."
    echo "   User data preserved. Reinstalling CPMM files in-place..."
    # No rm -rf — user data (learned/, plans/, projects/, sessions/) is safe
  elif [ "$LEGACY_CPMM" = true ]; then
    echo "⚠️  Detected legacy CPMM installation without marker, skipping backup."
    echo "   User data preserved. Reinstalling CPMM files in-place..."
    # No rm -rf — user data (learned/, plans/, projects/, sessions/) is safe
  else
    mv "$HOME/.claude" "$HOME/.claude.pre-cpmm"
    echo "📦 Backed up ~/.claude → ~/.claude.pre-cpmm"
  fi
fi

# Create required directories (user-owned dirs are never rm-rf'd)
# NITPICK #11: only create dirs not managed by rm-rf below
mkdir -p "$HOME/.claude/rules" "$HOME/.claude/skills/learned"
mkdir -p "$HOME/.claude/"{sessions,plans,projects}

# Copy core configurations
cp "$SCRIPT_DIR/.claude/CLAUDE.md" "$HOME/.claude/"
cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/"
# Copy settings.local.json from example template (only if not already present)
if [ ! -f "$HOME/.claude/settings.local.json" ] && [ -f "$SCRIPT_DIR/.claude/settings.local.example.json" ]; then
    cp "$SCRIPT_DIR/.claude/settings.local.example.json" "$HOME/.claude/settings.local.json"
fi

shopt -s nullglob

# agents/, commands/, contexts/ — fully CPMM managed: rm-rf to remove stale files
# EDGE CASE #6: these dirs are CPMM-only; user files should not be placed here
rm -rf "$HOME/.claude/agents" && mkdir -p "$HOME/.claude/agents"
_agent_files=("$SCRIPT_DIR/.claude/agents/"*.md)
if [ ${#_agent_files[@]} -gt 0 ]; then
  for agent in "${_agent_files[@]}"; do
    filename=$(basename "$agent")
    [[ "$filename" == README* ]] && continue
    [[ "$filename" == USER-MANUAL* ]] && continue
    cp "$agent" "$HOME/.claude/agents/"
  done
fi

rm -rf "$HOME/.claude/commands" && mkdir -p "$HOME/.claude/commands"
_cmd_files=("$SCRIPT_DIR/.claude/commands/"*.md)
if [ ${#_cmd_files[@]} -gt 0 ]; then
  for cmd in "${_cmd_files[@]}"; do
    filename=$(basename "$cmd")
    [[ "$filename" == README* ]] && continue
    [[ "$filename" == USER-MANUAL* ]] && continue
    cp "$cmd" "$HOME/.claude/commands/"
  done
fi

rm -rf "$HOME/.claude/contexts" && mkdir -p "$HOME/.claude/contexts"
_ctx_files=("$SCRIPT_DIR/.claude/contexts/"*.md)
if [ ${#_ctx_files[@]} -gt 0 ]; then
  for ctx in "${_ctx_files[@]}"; do
    filename=$(basename "$ctx")
    [[ "$filename" == README* ]] && continue
    [[ "$filename" == USER-MANUAL* ]] && continue
    cp "$ctx" "$HOME/.claude/contexts/"
  done
fi

# rules/ — language.md is user-owned: remove stale CPMM rules, preserve language.md
# BUG #2: rules loop is now inside nullglob block to prevent literal glob expansion
find "$HOME/.claude/rules/" -name "*.md" ! -name "language.md" -delete 2>/dev/null || true
for rule in "$SCRIPT_DIR/.claude/rules/"*.md; do
  [[ -f "$rule" ]] || continue  # nullglob guard (no-op with nullglob, safety net)
  filename=$(basename "$rule")
  [ "$filename" = "language.md" ] && continue
  [[ "$filename" == README* ]] && continue
  [[ "$filename" == USER-MANUAL* ]] && continue
  cp "$rule" "$HOME/.claude/rules/"
done

shopt -u nullglob

# managed skills/ and scripts/ — fully CPMM managed: rm-rf to remove stale files
for managed_skill in cli-patterns; do
  if [ -d "$SCRIPT_DIR/.claude/skills/$managed_skill" ]; then
    rm -rf "$HOME/.claude/skills/$managed_skill"
    cp -R "$SCRIPT_DIR/.claude/skills/$managed_skill" "$HOME/.claude/skills/"
  fi
done
# sessions/ dir created above; example files stay in repo only (not installed)
if [ -d "$SCRIPT_DIR/scripts" ]; then
  rm -rf "$HOME/.claude/scripts"
  cp -R "$SCRIPT_DIR/scripts" "$HOME/.claude/scripts"
fi

# Copy MCP Configuration
MCP_CONFIG_PRESENT=false
if [ -f "$SCRIPT_DIR/.claude.json" ]; then
  MCP_CONFIG_PRESENT=true

  if [ "$IS_UPDATE" = false ]; then
    if [ -f "$HOME/.claude.json" ]; then
      echo "📦 Backing up existing ~/.claude.json → ~/.claude.json.bak"
      cp "$HOME/.claude.json" "$HOME/.claude.json.bak"
    fi
    cp "$SCRIPT_DIR/.claude.json" "$HOME/.claude.json"
    echo "✅ Installed managed ~/.claude.json"
  elif [ ! -f "$HOME/.claude.json" ]; then
    cp "$SCRIPT_DIR/.claude.json" "$HOME/.claude.json"
    echo "✅ Restored missing ~/.claude.json from repository template"
  fi

  cleanup_managed_claude_json "$HOME/.claude.json"

  # ~/.claude.json is CPMM-managed. Regular-file ~/.mcp.json is user-managed.
  if [ -L "$HOME/.mcp.json" ]; then
    if [ "$(readlink "$HOME/.mcp.json" 2>/dev/null)" != "$HOME/.claude.json" ]; then
      ln -sf "$HOME/.claude.json" "$HOME/.mcp.json"
      echo "✅ Ensured managed .mcp.json → .claude.json symlink"
    fi
  elif [ -f "$HOME/.mcp.json" ]; then
    echo "⚠️  Leaving regular ~/.mcp.json untouched (user-managed file)."
    if user_mcp_contains_legacy_context7 "$HOME/.mcp.json"; then
      echo "   Detected legacy Context7 MCP in ~/.mcp.json."
      echo "   Remove it manually if you no longer want the legacy MCP path."
    fi
  else
    ln -s "$HOME/.claude.json" "$HOME/.mcp.json"
    if [ "$IS_UPDATE" = true ]; then
      echo "✅ Restored missing .mcp.json → .claude.json symlink"
    else
      echo "✅ Created .mcp.json → .claude.json symlink"
    fi
  fi
fi

# Perplexity setup + language selection (Fresh Install Only)
if [ "$IS_UPDATE" = false ]; then
  # EDGE CASE #8: check stdin is truly a terminal (not /dev/tty char-device trick)
  # [ -c /dev/tty ] is always true on Linux/macOS — use [ -t 0 ] alone
  if [ "$MCP_CONFIG_PRESENT" = true ] && [ -t 0 ]; then
    if ! command -v jq &> /dev/null; then
      echo "⚠️  Skipping Perplexity setup (jq not installed). Install jq and re-run to configure."
    else
      echo ""
      echo "🔍 Perplexity API Setup (Recommended for /dplan)"
      echo -n "   Enter your API Key (Press Enter to skip): "
      read -rs PERPLEXITY_KEY < /dev/tty || PERPLEXITY_KEY=""
      echo "" # Newline for silent read

      if [ -n "$PERPLEXITY_KEY" ]; then
        # Enable Perplexity (use env var to avoid key exposure in process list)
        # EDGE CASE #10: write to tmp then atomically rename; trap cleans up on failure
        PERPLEXITY_API_KEY="$PERPLEXITY_KEY" jq \
          '.mcpServers.perplexity = .mcpServers._perplexity_disabled_by_default |
           .mcpServers.perplexity.env.PERPLEXITY_API_KEY = env.PERPLEXITY_API_KEY |
           del(.mcpServers._perplexity_disabled_by_default)' \
          "$HOME/.claude.json" > "$HOME/.claude.json.tmp"
        mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"
        # BUG #5: unset both variables
        unset PERPLEXITY_KEY PERPLEXITY_API_KEY
        echo "✅ Perplexity API Key configured!"
      else
        # Skip: Completely remove the disabled block to keep config clean
        echo "⚠️  Skipping Perplexity setup. Disabling feature..."
        jq 'del(.mcpServers._perplexity_disabled_by_default)' \
          "$HOME/.claude.json" > "$HOME/.claude.json.tmp"
        mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"
        echo "   (Feature removed from config. Add manually to functionality if needed)"
      fi
    fi
  fi

  # Language Selection (Interactive - Fresh Install Only)
  if [ -t 0 ]; then
    echo ""
    echo "🌍 Output Language"
    echo "   1) English (default)"
    echo "   2) 한국어 (Korean)"
    echo "   3) 日本語 (Japanese)"
    echo "   4) 中文 (Chinese)"
    echo -n "   Select [1-4]: "
    read -r LANG_CHOICE < /dev/tty || LANG_CHOICE="1"

    case $LANG_CHOICE in
      2)
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Korean (한국어). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Korean"
        ;;
      3)
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Japanese (日本語). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Japanese"
        ;;
      4)
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Chinese (中文). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Chinese"
        ;;
      *)
        # English: no language.md needed (Claude defaults to English)
        rm -f "$HOME/.claude/rules/language.md"
        echo "✅ Output language: English"
        ;;
    esac
  fi
fi

offer_context7_setup

# EDGE CASE #9: guard find against missing dir (scripts/ may not exist on minimal installs)
# Make scripts executable (Recursive)
if [ -d "$HOME/.claude/scripts" ]; then
  find "$HOME/.claude/scripts" -name "*.sh" -exec chmod +x {} \;
  find "$HOME/.claude/scripts" -name "*.js" -exec chmod +x {} \;
fi

# Write installation marker
# SEC #4: avoid node -p with interpolated $SCRIPT_DIR (injection risk); use node -e with argument
PROJECT_VERSION=$(node -e "try{process.stdout.write(require(process.argv[1]).version)}catch(e){process.exit(1)}" \
  "$SCRIPT_DIR/package.json" 2>/dev/null || \
  grep '"version"' "$SCRIPT_DIR/package.json" 2>/dev/null | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || \
  echo "unknown")
printf '%s\ninstalled:%s\n' "$PROJECT_VERSION" "$(date)" > "$CPMM_MARKER"

# Old backup cleanup hint
OLD_BACKUPS=$(find "$HOME" -maxdepth 1 -name ".claude-backup-*" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$OLD_BACKUPS" -gt 0 ]; then
  echo ""
  echo "💡 Old backups detected: $OLD_BACKUPS directory(ies) named ~/.claude-backup-*"
  echo "   Review and remove: rm -rf ~/.claude-backup-*"
fi

# Final success message showing mode
echo ""
if [ "$IS_UPDATE" = true ]; then
  echo "✅ Update complete!"
else
  echo "✅ Installation complete!"
fi
echo ""
echo "Quick Start:"
echo "  claude"
echo "  > /plan Design a new feature"
echo "  > /dplan Analyze complex architecture"
echo "  > /do Implement the login page"
echo ""
echo "Dependency Check:"
echo "  cpmm setup       # install missing deps (jq, mgrep, tmux) + offer ctx7 install + official Context7/RTK setup"
echo "  cpmm doctor      # check status only"
echo ""
echo "Context7 (Optional Official Integration):"
if context7_official_integration_installed; then
  echo "  Installed: official Context7 Claude integration"
else
  echo "  Re-run cpmm setup in an interactive terminal to opt in"
fi
if context7_cli_installed; then
  echo "  CLI: ctx7 ($(ctx7 --version 2>/dev/null | head -1 || echo 'installed'))"
else
  echo "  Manual CLI install: npm install -g ctx7"
fi
echo "  Manual official setup: ctx7 setup --cli --claude"
echo ""
if command -v rtk >/dev/null 2>&1; then
  echo "RTK (Optional Integration):"
  echo "  Installed: rtk"
  echo "  Enable hook: rtk init -g --hook-only"
  echo "  Recommended Bash hook order in ~/.claude/settings.json:"
  echo "    1) ~/.claude/scripts/hooks/critical-action-check.sh  (timeout: 5)"
  echo "    2) ~/.claude/hooks/rtk-rewrite.sh                    (timeout: 10)"
  echo "  Rollback: rtk init -g --uninstall"
  echo ""
fi
if [ "$HAS_EXISTING_RTK_HOOK" = true ]; then
  echo "RTK Update Note:"
  echo "  An RTK hook was detected before this CPMM update."
  if [ "${CPMM_SETUP_WRAPPER:-}" = "1" ]; then
    echo "  cpmm setup will restore the managed RTK hook order and timeout after rewriting settings."
    echo "  Run: cpmm doctor"
  else
    echo "  Re-run cpmm setup to restore the managed RTK hook order and timeout."
    echo "  Or re-check ~/.claude/settings.json manually, then run: cpmm doctor"
  fi
  echo ""
fi
echo "Language:"
echo "  To change language: edit ~/.claude/rules/language.md"
echo "  To use English: rm ~/.claude/rules/language.md"
