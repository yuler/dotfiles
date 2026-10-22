#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "AI Agents Configuration"

user_md="$DOTFILES_DIR/agents/USER.md"
if [ ! -f "$user_md" ]; then
  log_error "File not found: $user_md"
  exit 1
fi

# 1. Base standard location
link_file "$user_md" "$HOME/.agents/USER.md"

# 2. Smart distribution to detected harnesses
[ -d "$HOME/.openclaw" ] && link_file "$user_md" "$HOME/.openclaw/workspace/USER.md"

# Claude Code: link ~/.claude/USER.md and safely transclude in ~/.claude/CLAUDE.md
if [ -d "$HOME/.claude" ]; then
  link_file "$user_md" "$HOME/.claude/USER.md"
  claude_md="$HOME/.claude/CLAUDE.md"
  if [ -f "$claude_md" ]; then
    if ! grep -q "@USER.md" "$claude_md"; then
      echo "" >> "$claude_md"
      echo "@USER.md" >> "$claude_md"
      log_success "Appended @USER.md reference to $claude_md"
    else
      log_info "$claude_md already includes @USER.md"
    fi
  else
    echo "@USER.md" > "$claude_md"
    log_success "Created $claude_md with @USER.md reference"
  fi
fi

# Cursor: link ~/.cursorrules and ~/.cursor/rules/USER.md
if [ -d "$HOME/.cursor" ]; then
  link_file "$user_md" "$HOME/.cursorrules"
  link_file "$user_md" "$HOME/.cursor/rules/USER.md"
fi

# Gemini / Antigravity
[ -d "$HOME/.gemini" ] && link_file "$user_md" "$HOME/.gemini/config/rules/USER.md"

log_success "AI Agents configuration completed."
