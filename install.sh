#!/bin/bash
# Sober - Installation Script
set -e

# Error handler: print failure line and exit message
_on_error() { echo ""; echo "❌ Installation failed at line $1. Check output above."; }
trap '_on_error $LINENO' ERR

# Resolve the source tree. Sober installs from sources sitting next to this
# script — either the npm package (`sober install` runs this) or a git clone.
_self="${BASH_SOURCE[0]}"
if [[ -n "$_self" && "$_self" != "bash" ]]; then
  SCRIPT_DIR="$( cd "$( dirname "$_self" )" && pwd )"
fi
if [ -z "${SCRIPT_DIR:-}" ] || [ ! -f "$SCRIPT_DIR/AGENTS.md" ] || [ ! -f "$SCRIPT_DIR/package.json" ]; then
  echo "❌ Run Sober from its package or a clone — sources must sit beside install.sh."
  echo "   npm:    npm install -g getsober && sober install"
  echo "   source: git clone https://github.com/move-hoon/sober.git && cd sober && bash install.sh"
  exit 1
fi

# Single home: ~/.sober holds the source of truth; the runtimes symlink into it.
SOBER_HOME="$HOME/.sober"

# Marker-based detection for Install vs Update
SOBER_MARKER="$SOBER_HOME/.sober-version"
IS_UPDATE=false
if [ -f "$SOBER_MARKER" ]; then IS_UPDATE=true; fi

# Header message: show Install vs Update mode
if [ "$IS_UPDATE" = true ]; then
  echo "🔄 Updating Sober"
  INSTALLED_VERSION=$(head -1 "$SOBER_MARKER" 2>/dev/null || echo "unknown")
  echo "   Current version: $INSTALLED_VERSION"
else
  echo "🚀 Installing Sober"
fi

# Preflight — be explicit and honest. Sober keeps its source of truth in ~/.sober
# and adds itself to your runtimes additively; it never overwrites or deletes
# your existing config.
echo "   Sober keeps its source of truth in ~/.sober and adds itself to your runtimes,"
echo "   never overwriting or deleting your existing config:"
echo "     • Claude settings.json + Codex hooks.json: merges in only Sober's hooks — your hooks are kept (first merge is backed up)"
echo "     • global CLAUDE.md / AGENTS.md / ~/.codex/AGENTS.md: adds a Sober block, or symlinks if the file is absent"
echo "     • skills/commands/rules/Codex rules: links Sober's own; your files and non-Sober symlinks are left in place"
echo "     • never touched: ~/.claude/scripts, ~/.claude.json, settings.local.json, ~/.claude/skills/learned"
echo "     • backed up before any change (timestamped): a real settings.json, rules/language.md (language step)"

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
  echo "   Re-run sober setup in an interactive terminal to opt in, or run the official commands directly:"
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
  local choice="${SOBER_CONTEXT7_SETUP_CHOICE:-}"

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

# --- Review execution -------------------------------------------------------
# Sober ships the portable review contract (skills/sober-review). It does not
# install runtime-specific reviewer agents or assume a Claude plugin exists.
# Users can ask Claude Code or Codex to run the contract in a separate read-only
# helper when their runtime supports helper/subagent workflows.

# --- Optional local search/edit tools --------------------------------------
# Sober works best when plain command-line tools do the repeatable search and
# bulk-edit work. These tools are optional: setup offers them, but never fails
# just because one is missing. Best-effort; failure is advisory.
substrate_present() {
  command -v rg >/dev/null 2>&1 && command -v ast-grep >/dev/null 2>&1 && command -v probe >/dev/null 2>&1
}

install_ripgrep() {
  command -v rg >/dev/null 2>&1 && { echo "   ripgrep: already present"; return 0; }
  if command -v brew >/dev/null 2>&1; then brew install ripgrep && return 0; fi
  if command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y ripgrep && return 0; fi
  if command -v dnf >/dev/null 2>&1; then sudo dnf install -y ripgrep && return 0; fi
  if command -v cargo >/dev/null 2>&1; then cargo install ripgrep && return 0; fi
  echo "   ⚠️ ripgrep: install manually — https://github.com/BurntSushi/ripgrep#installation"; return 1
}

install_ast_grep() {
  command -v ast-grep >/dev/null 2>&1 && { echo "   ast-grep: already present"; return 0; }
  if command -v npm >/dev/null 2>&1; then npm install -g @ast-grep/cli && return 0; fi
  if command -v brew >/dev/null 2>&1; then brew install ast-grep && return 0; fi
  if command -v cargo >/dev/null 2>&1; then cargo install ast-grep && return 0; fi
  echo "   ⚠️ ast-grep: install manually — npm i -g @ast-grep/cli"; return 1
}

install_probe() {
  command -v probe >/dev/null 2>&1 && { echo "   Probe: already present"; return 0; }
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/buger/probe/main/install.sh | bash && return 0
  fi
  echo "   ⚠️ Probe: install manually — https://github.com/buger/probe"; return 1
}

offer_substrate() {
  local choice="${SOBER_SUBSTRATE_CHOICE:-}"

  if substrate_present; then
    echo ""
    echo "🛠  Deterministic toolkit"
    echo "   ripgrep + ast-grep + Probe already present."
    return 0
  fi

  if [ -z "$choice" ] && [ ! -t 0 ]; then
    echo ""
    echo "🛠  Deterministic toolkit (Optional)"
    echo "   Skipped in non-interactive mode. Sober works without it but saves far less."
    echo "   Install later: ripgrep, ast-grep (npm i -g @ast-grep/cli), Probe. See: sober doctor"
    return 0
  fi

  case "$choice" in
    install|skip) ;;
    *) choice="" ;;
  esac

  if [ -z "$choice" ]; then
    echo ""
    echo "🛠  Deterministic toolkit (Optional, Recommended)"
    echo "   These do fast search and safe bulk edits — the core of how Sober saves quota."
    echo "   Sober runs without them, but the policies have nothing to offload to."
    echo "   Install ripgrep + ast-grep + Probe now?"
    echo "   1) Yes (Recommended)"
    echo "   2) Skip — I'll add them later (sober doctor shows how)"
    echo -n "   Select [1-2]: "
    read -r SUB_CHOICE < /dev/tty || SUB_CHOICE="2"
    case $SUB_CHOICE in
      1) choice="install" ;;
      *) choice="skip" ;;
    esac
  fi

  if [ "$choice" = "install" ]; then
    echo ""
    echo "🛠  Installing deterministic toolkit (best-effort)..."
    install_ripgrep || true
    install_ast_grep || true
    install_probe || true
    echo "   (Serena LSP is a separate, opt-in MCP — see sober doctor for setup.)"
  else
    echo ""
    echo "⚠️  Skipping toolkit. Add it anytime — sober doctor lists the install commands."
  fi
}

# Deploy a flat set of managed *.md files (e.g. commands/) into ~/.sober and
# symlink each into the REAL ~/.claude/<name> dir. User-authored files in that dir
# are left untouched; only Sober-owned symlinks (target under ~/.sober) are
# refreshed. READMEs/manuals are human docs and never shipped as agent context.
deploy_managed_files() {
  local name="$1"
  local src="$SCRIPT_DIR/.claude/$name"
  local dest="$SOBER_HOME/$name"
  rm -rf "$dest"; mkdir -p "$dest" "$HOME/.claude/$name"
  # Remove only Sober-owned symlinks so renamed/dropped managed files don't dangle.
  for existing in "$HOME/.claude/$name/"*; do
    [ -L "$existing" ] || continue
    case "$(readlink "$existing")" in "$SOBER_HOME/"*) rm -f "$existing" ;; esac
  done
  [ -d "$src" ] || return 0
  for f in "$src/"*.md; do
    [[ -f "$f" ]] || continue
    local b; b=$(basename "$f")
    [[ "$b" == README* || "$b" == USER-MANUAL* ]] && continue
    cp "$f" "$dest/$b"
    # Never clobber a real user file OR a user-owned symlink sharing the name —
    # only refresh Sober's own symlink (target under ~/.sober).
    local cur="$HOME/.claude/$name/$b"
    if [ -L "$cur" ]; then
      case "$(readlink "$cur")" in
        "$SOBER_HOME/"*) : ;;
        *) echo "⚠️  Leaving your symlink untouched (name clashes with a Sober $name): $cur"; continue ;;
      esac
    elif [ -e "$cur" ]; then
      echo "⚠️  Leaving your file untouched (name clashes with a Sober $name): $cur"
      continue
    fi
    rm -f "$cur"
    ln -s "$dest/$b" "$cur"
  done
}

# No whole-directory move. Sober deploys per-file (skills/commands/rules as
# Sober-owned symlinks, scripts backed up if a real dir exists, settings.json
# backed up before overwrite), so an existing ~/.claude — including the user's
# own agents/commands/rules/settings — is preserved in place on both fresh
# install and update.

# Create required directories (user-owned dirs are never rm-rf'd)
mkdir -p "$HOME/.claude/rules" "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/"{plans,projects}
# Single home: ~/.sober is the source of truth; runtimes hold symlinks into it.
mkdir -p "$SOBER_HOME/skills" "$HOME/.agents/skills" "$HOME/.codex" "$HOME/.codex/rules"

# Core spine — AGENTS.md lives once in ~/.sober. Add it to each runtime entrypoint
# additively:
#   - absent (or already a Sober symlink) → symlink to the single source
#   - a real Claude file → insert/refresh a small @import block (Claude supports it)
#   - a real Codex file → insert/refresh the full Sober text (Codex documents AGENTS.md
#     loading, not @import expansion)
#   - a foreign symlink (dotfiles) → leave it and tell the user how to opt in manually
cp "$SCRIPT_DIR/AGENTS.md" "$SOBER_HOME/AGENTS.md"
SOBER_BLOCK_START="<!-- SOBER:START -->"
SOBER_BLOCK_END="<!-- SOBER:END -->"
link_or_block_spine() {
  local target="$1"
  local mode="${2:-import}" # import | inline
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$(dirname "$target")"
    ln -s "$SOBER_HOME/AGENTS.md" "$target"
    return
  fi
  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$SOBER_HOME/AGENTS.md" ]; then return; fi
    if [ "$mode" = "inline" ]; then
      echo "⚠️  $target is your own symlink — add the Sober block from $SOBER_HOME/AGENTS.md to its target to load Sober."
    else
      echo "⚠️  $target is your own symlink — add '@$SOBER_HOME/AGENTS.md' to its target to load the Sober spine."
    fi
    return
  fi
  # real file → insert/refresh the managed block at the top, preserving user content
  local tmp; tmp="$(mktemp)"
  {
    printf '%s\n' "$SOBER_BLOCK_START"
    if [ "$mode" = "inline" ]; then
      cat "$SOBER_HOME/AGENTS.md"
    else
      printf '@%s/AGENTS.md\n' "$SOBER_HOME"
    fi
    printf '%s\n\n' "$SOBER_BLOCK_END"
    awk -v s="$SOBER_BLOCK_START" -v e="$SOBER_BLOCK_END" '
      $0==s {inblk=1; next} $0==e {inblk=0; next} !inblk {print}
    ' "$target"
  } > "$tmp"
  if cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
  else
    cp "$target" "$target.pre-sober.$(date +%Y%m%d%H%M%S)"
    mv "$tmp" "$target"
    echo "📦 Added the Sober block to $target (your content kept; backup saved)"
  fi
}
link_or_block_spine "$HOME/.claude/CLAUDE.md" import
link_or_block_spine "$HOME/.claude/AGENTS.md" import
link_or_block_spine "$HOME/.codex/AGENTS.md" inline
# settings.json — additive, not a takeover. Sober MERGES its hooks (and a few safe
# permission/env defaults) into your existing ~/.claude/settings.json, preserving
# your env, permissions, and hooks. On a fresh file it installs Sober's defaults.
# The first merge is backed up (timestamped); later merges are idempotent no-ops.
if [ -f "$HOME/.claude/settings.json" ]; then
  if command -v node >/dev/null 2>&1; then
    if ! grep -q '\.sober/scripts/hooks/' "$HOME/.claude/settings.json"; then
      cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.pre-sober.$(date +%Y%m%d%H%M%S)"
      echo "📦 Backed up settings.json before merging Sober hooks"
    fi
    node "$SCRIPT_DIR/scripts/lib/merge-settings.js" install "$HOME/.claude/settings.json" "$SCRIPT_DIR/.claude/settings.json" \
      && echo "✅ Merged Sober hooks into your existing settings.json (your config preserved)"
  else
    echo "⚠️  node not found — left settings.json untouched. Re-run with node to add Sober hooks."
  fi
else
  cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
fi

# Codex hooks — same lifecycle guardrails as Claude Code, installed additively in
# ~/.codex/hooks.json. Existing Codex hooks remain; only Sober-owned handlers are
# refreshed. Codex will ask the user to trust non-managed hook definitions via /hooks.
if [ -f "$SCRIPT_DIR/codex/hooks.json" ]; then
  if command -v node >/dev/null 2>&1; then
    if [ -f "$HOME/.codex/hooks.json" ] && ! grep -q '\.sober/scripts/' "$HOME/.codex/hooks.json"; then
      cp "$HOME/.codex/hooks.json" "$HOME/.codex/hooks.json.pre-sober.$(date +%Y%m%d%H%M%S)"
      echo "📦 Backed up hooks.json before merging Sober Codex hooks"
    fi
    node "$SCRIPT_DIR/scripts/lib/merge-codex-hooks.js" install "$HOME/.codex/hooks.json" "$SCRIPT_DIR/codex/hooks.json" \
      && echo "✅ Merged Sober hooks into your Codex hooks.json (your hooks preserved)"
  else
    echo "⚠️  node not found — left Codex hooks.json untouched. Re-run with node to add Sober hooks."
  fi
fi

# Codex rules — official Starlark exec-policy layer. Symlink only Sober-owned rule
# files; preserve any real user rule file with the same name.
if [ -d "$SCRIPT_DIR/codex/rules" ]; then
  rm -rf "$SOBER_HOME/codex-rules"
  mkdir -p "$SOBER_HOME/codex-rules" "$HOME/.codex/rules"
  cp -R "$SCRIPT_DIR/codex/rules/." "$SOBER_HOME/codex-rules/"
  for src in "$SOBER_HOME"/codex-rules/*.rules; do
    [ -e "$src" ] || continue
    target="$HOME/.codex/rules/$(basename "$src")"
    if [ -L "$target" ]; then
      case "$(readlink "$target")" in
        "$SOBER_HOME/"*) : ;;
        *) echo "⚠️  Leaving your Codex rule symlink untouched: $target"; continue ;;
      esac
    elif [ -e "$target" ]; then
      echo "⚠️  Leaving your Codex rule untouched (name clashes with Sober): $target"
      continue
    fi
    rm -f "$target"
    ln -s "$src" "$target"
  done
fi
# settings.local.json is the user layer: seed it from the example only if absent.
if [ ! -f "$HOME/.claude/settings.local.json" ] && [ -f "$SCRIPT_DIR/.claude/settings.local.example.json" ]; then
    cp "$SCRIPT_DIR/.claude/settings.local.example.json" "$HOME/.claude/settings.local.json"
fi

shopt -s nullglob

# commands/ — Sober ships measure + analyze-failures. Symlink them per-file into
# the real ~/.claude/commands dir so the user's own commands coexist.
# (Sober ships no agents, so ~/.claude/agents is left entirely alone.)
deploy_managed_files commands

# rules/ — same safe per-file deploy as commands. Only Sober-owned rule symlinks
# are refreshed; user rules and the real files language.md (user) and context7.md
# (Context7 setup) are left untouched. language.md is written later by the
# language step; it is never in the shipped source.
deploy_managed_files rules

shopt -u nullglob

# managed skills — single source in ~/.sober/skills, symlinked into BOTH runtimes
# (~/.claude/skills for Claude, ~/.agents/skills for Codex per its official docs).
# Do not remove ~/.claude/skills/learned: user-owned.
for managed_skill in karpathy caveman search-ladder edit-deterministic observe structure-graph sober-review; do
  if [ -d "$SCRIPT_DIR/.claude/skills/$managed_skill" ]; then
    # single source in ~/.sober
    rm -rf "$SOBER_HOME/skills/$managed_skill"
    cp -R "$SCRIPT_DIR/.claude/skills/$managed_skill" "$SOBER_HOME/skills/$managed_skill"
    # symlink both runtimes to the single source. Replace a prior symlink, but
    # never delete a real user skill dir that happens to share the name.
    for runtime_skills in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
      target="$runtime_skills/$managed_skill"
      if [ -L "$target" ]; then
        case "$(readlink "$target")" in
          "$SOBER_HOME/"*) : ;;
          *) echo "⚠️  Leaving your skill symlink untouched (name clashes with a Sober skill): $target"; continue ;;
        esac
      elif [ -e "$target" ]; then
        echo "⚠️  Leaving your skill untouched (name clashes with a Sober skill): $target"
        continue
      fi
      rm -rf "$target"
      ln -s "$SOBER_HOME/skills/$managed_skill" "$target"
    done
  fi
done

# scripts/ (hooks) — live ONLY in ~/.sober. Sober's settings.json hooks reference
# ~/.sober/scripts/hooks/*.sh directly, so ~/.claude/scripts is never touched —
# your own ~/.claude/scripts stays exactly as it is.
if [ -d "$SCRIPT_DIR/scripts" ]; then
  rm -rf "$SOBER_HOME/scripts"
  cp -R "$SCRIPT_DIR/scripts" "$SOBER_HOME/scripts"
  # Clean up a stale pre-2.x symlink Sober used to create at ~/.claude/scripts.
  if [ -L "$HOME/.claude/scripts" ]; then
    case "$(readlink "$HOME/.claude/scripts")" in "$SOBER_HOME/scripts") rm -f "$HOME/.claude/scripts" ;; esac
  fi
fi

# Sober intentionally does not install a Codex reviewer role. The review
# contract is portable; execution should use the runtime's native helper-agent
# workflow or a user-owned custom agent when the user wants one.

# Sober ships no MCP servers and never touches ~/.claude.json (Claude Code's own
# state: projects, history, MCP, auth). Nothing to do here.

# Prepare ~/.claude/rules/language.md before the language step writes or removes
# it: back up a real user file (timestamp) and unlink a symlink so we never write
# through it to its target. After this the path is clear.
prepare_language_md() {
  local f="$HOME/.claude/rules/language.md"
  if [ -L "$f" ]; then
    rm -f "$f"
  elif [ -f "$f" ]; then
    mv "$f" "$f.pre-sober.$(date +%Y%m%d%H%M%S)"
    echo "📦 Backed up existing language.md"
  fi
}

# Language selection (Fresh Install Only)
if [ "$IS_UPDATE" = false ]; then
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

    # Every branch first preserves any existing user file (backup real / unlink
    # symlink) via prepare_language_md, then writes — or, for English, leaves none.
    case $LANG_CHOICE in
      2)
        prepare_language_md
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Korean (한국어). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Korean"
        ;;
      3)
        prepare_language_md
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Japanese (日本語). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Japanese"
        ;;
      4)
        prepare_language_md
        cat > "$HOME/.claude/rules/language.md" <<'LANGEOF'
# Language Policy
Respond in Chinese (中文). Code, commands, technical terms in English.
LANGEOF
        echo "✅ Output language: Chinese"
        ;;
      1)
        # Explicit English reset: back up any existing policy, then leave none.
        prepare_language_md
        echo "✅ Output language: English"
        ;;
      *)
        # Enter / unknown: keep an existing language policy untouched; only default
        # to English when there is none. Never silently drop a user's policy.
        if [ -e "$HOME/.claude/rules/language.md" ] || [ -L "$HOME/.claude/rules/language.md" ]; then
          echo "✅ Keeping your current language policy (choose 1 to reset to English)"
        else
          echo "✅ Output language: English (default)"
        fi
        ;;
    esac
  fi
fi

# Optional-tool offers belong to `sober setup`, not `sober install`. Default OFF so
# a direct `bash install.sh` behaves like `sober install` (config only) and never
# auto-runs a tool installer (offer_substrate → install_probe shells curl|bash).
# `sober setup` opts in by exporting SOBER_WITH_OFFERS=1.
if [ "${SOBER_WITH_OFFERS:-0}" = "1" ]; then
  offer_context7_setup
  offer_substrate
fi

# Make scripts executable in the single source (hooks reference ~/.sober/scripts directly).
if [ -d "$SOBER_HOME/scripts" ]; then
  find "$SOBER_HOME/scripts" -name "*.sh" -exec chmod +x {} \;
  find "$SOBER_HOME/scripts" -name "*.js" -exec chmod +x {} \;
fi

# Write installation marker
# SEC #4: avoid node -p with interpolated $SCRIPT_DIR (injection risk); use node -e with argument
PROJECT_VERSION=$(node -e "try{process.stdout.write(require(process.argv[1]).version)}catch(e){process.exit(1)}" \
  "$SCRIPT_DIR/package.json" 2>/dev/null || \
  grep '"version"' "$SCRIPT_DIR/package.json" 2>/dev/null | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || \
  echo "unknown")
printf '%s\ninstalled:%s\n' "$PROJECT_VERSION" "$(date)" > "$SOBER_MARKER"

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
echo "  > Implement the login page   # just ask — the spine governs batch + verify + rollback"
echo "  > (enter native plan mode for multi-file architecture)"
echo "  > /measure baseline   # before/after KPI when changing the harness"
echo ""
echo "Manage Sober (everything lives in ~/.sober; runtimes symlink into it):"
echo "  sober doctor      # check install + deterministic-substrate + Context7 status"
echo "  sober install     # re-apply / refresh the policy files (this script)"
echo "  sober setup       # install deps (jq) + offer Context7 + optional toolkit"
echo "  sober uninstall   # remove Sober's symlinks and ~/.sober"
echo ""
echo "Context7 (Optional Official Integration):"
if context7_official_integration_installed; then
  echo "  Installed: official Context7 Claude integration"
else
  echo "  Re-run sober setup in an interactive terminal to opt in"
fi
if context7_cli_installed; then
  echo "  CLI: ctx7 ($(ctx7 --version 2>/dev/null | head -1 || echo 'installed'))"
else
  echo "  Manual CLI install: npm install -g ctx7"
fi
echo "  Manual official setup: ctx7 setup --cli --claude"
echo ""
echo "Language:"
echo "  To change language: edit ~/.claude/rules/language.md"
echo "  To use English: rm ~/.claude/rules/language.md"
echo ""
echo "Codex CLI:"
echo "  Reads the same spine via ~/.codex/AGENTS.md, skills via ~/.agents/skills,"
echo "  hooks via ~/.codex/hooks.json, and safety rules via ~/.codex/rules/."
echo "  Open /hooks once in Codex to review/trust the installed hook definitions."
echo "  Optional: set tool_output_token_limit in ~/.codex/config.toml to keep tool output short."
