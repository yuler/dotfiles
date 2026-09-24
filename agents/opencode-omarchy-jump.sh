#!/bin/bash
# Jump to the terminal running opencode for $1 (project cwd), then focus it.
# Used by opencode notifications (opencode-omarchy-notify plugin --exec on click).
#
# Source of truth: ~/Projects/dotfiles/agents/opencode-omarchy-jump.sh
# (symlinked to ~/.config/opencode/plugins/opencode-omarchy-jump.sh).
#
# Strategy, in order:
#   1. tmux: pick the pane whose cwd == target, preferring the one actually
#      running opencode (same cwd often hosts nvim/shell panes too). Map its
#      session to the visible foot via tmux clients + PPID ancestry -> Hyprland
#      pid (exact, no title guessing). Detached sessions retarget the visible
#      tmux foot's client instead of falling back to a random foot.
#   2. bare foot: opencode/herdr/dev servers can run outside tmux — match a
#      foot whose descendant cwd == target (via /proc).
# Focus goes through omarchy's hl.dsp.focus (auto-switches workspace and
# auto-shows scratchpad), with plain focuswindow as fallback.
set -u

d="${1:?usage: opencode-omarchy-jump <cwd>}"
target="$(realpath -m "$d" 2>/dev/null || printf '%s' "$d")"

focus_foot() {
  local addr="$1"
  [ -n "$addr" ] || return 0
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null 2>&1 ||
    hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
}

# Walk up from $1; echo the enclosing foot pid if there is one.
foot_ancestor_of() {
  local pid="$1" comm ppid
  while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
    if [ "$comm" = "foot" ]; then
      printf '%s' "$pid"
      return 0
    fi
    ppid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
    [ -n "$ppid" ] || return 1
    pid="$ppid"
  done
  return 1
}

# foot pid -> hyprland address (exact, via hypr's own pid field).
foot_addr_of() {
  hyprctl clients -j 2>/dev/null |
    jq -r --argjson pid "$1" 'first(.[] | select(.class == "foot" and .pid == $pid)).address // empty'
}

# ---- 1. tmux panes with matching cwd ----
best_ref="" best_sess="" best_win="" best_pane="" best_score=99
if tmux list-sessions >/dev/null 2>&1; then
  # Pane pids that (transitively) parent an opencode process.
  declare -A pane_pids=()
  while IFS='|' read -r sess win pane cwd cmd pid _active; do
    [ -n "${sess:-}" ] || continue
    pane_pids["$pid"]=1
  done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{pane_index}|#{pane_current_path}|#{pane_current_command}|#{pane_pid}|#{pane_active}' 2>/dev/null)

  declare -A opencode_panes=()
  if [ "${#pane_pids[@]}" -gt 0 ]; then
    # Our own ancestry also matches `pgrep -f opencode` (this script's name
    # contains it) — exclude it so we never boost our own pane.
    declare -A self_chain=()
    p="$$"
    while [ -n "$p" ] && [ "$p" != "0" ] && [ "$p" != "1" ]; do
      self_chain["$p"]=1
      p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
    done
    while read -r opid; do
      [ -n "$opid" ] || continue
      [ -z "${self_chain[$opid]:-}" ] || continue
      p="$opid"
      while [ -n "$p" ] && [ "$p" != "0" ] && [ "$p" != "1" ]; do
        if [ -n "${pane_pids[$p]:-}" ]; then
          opencode_panes["$p"]=1
          break
        fi
        p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
      done
    done < <(pgrep -f 'opencode' 2>/dev/null || true)
  fi

  while IFS='|' read -r sess win pane cwd cmd pid active; do
    [ -n "${sess:-}" ] || continue
    rcwd="$(realpath -m "$cwd" 2>/dev/null || printf '%s' "$cwd")"
    [ "$rcwd" = "$target" ] || continue
    score=2
    if [ "$cmd" = "opencode" ] || [ -n "${opencode_panes[$pid]:-}" ]; then
      score=0
    elif [ "$active" = "1" ]; then
      score=1
    fi
    if [ "$score" -lt "$best_score" ]; then
      best_score="$score"
      best_ref="$sess:$win.$pane"
      best_sess="$sess" best_win="$win" best_pane="$pane"
    fi
  done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{pane_index}|#{pane_current_path}|#{pane_current_command}|#{pane_pid}|#{pane_active}' 2>/dev/null)
fi

if [ -n "$best_ref" ]; then
  # Which foot shows this session? Resolve via client pid ancestry, not titles.
  target_addr="" fallback_tty="" fallback_addr=""
  while IFS='|' read -r csession cpid ctty; do
    [ -n "${csession:-}" ] || continue
    fpid="$(foot_ancestor_of "$cpid" || true)"
    [ -n "$fpid" ] || continue
    addr="$(foot_addr_of "$fpid")"
    [ -n "$addr" ] || continue
    if [ "$csession" = "$best_sess" ] && [ -z "$target_addr" ]; then
      target_addr="$addr"
    fi
    if [ -z "$fallback_addr" ]; then
      fallback_tty="$ctty"
      fallback_addr="$addr"
    fi
  done < <(tmux list-clients -F '#{client_session}|#{client_pid}|#{client_tty}' 2>/dev/null || true)

  if [ -n "$target_addr" ]; then
    tmux select-window -t "$best_sess:$best_win" 2>/dev/null
    tmux select-pane -t "$best_ref" 2>/dev/null
    focus_foot "$target_addr"
    exit 0
  fi

  # Session is detached (no foot shows it): retarget the visible tmux foot.
  if [ -n "$fallback_addr" ] && [ -n "$fallback_tty" ]; then
    tmux switch-client -c "$fallback_tty" -t "$best_sess:$best_win" 2>/dev/null
    tmux select-pane -t "$best_ref" 2>/dev/null
    focus_foot "$fallback_addr"
    exit 0
  fi

  # No tmux foot at all — still select the pane, then try a bare-foot match.
  tmux select-window -t "$best_sess:$best_win" 2>/dev/null
  tmux select-pane -t "$best_ref" 2>/dev/null
fi

# ---- 2. bare foot: descendant cwd == target (herdr, dev servers, plain shell) ----
if command -v hyprctl >/dev/null 2>&1; then
  declare -A children=()
  while read -r pid ppid; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    children["$ppid"]+="$pid "
  done < <(ps -eo pid=,ppid= 2>/dev/null || true)

  mapfile -t foot_pids < <(hyprctl clients -j 2>/dev/null |
    jq -r '.[] | select(.class == "foot") | .pid // empty')

  best_foot="" best_depth=999999
  for fpid in "${foot_pids[@]}"; do
    # BFS from the foot pid.
    queue=("$fpid:0")
    visited=" $fpid "
    while [ "${#queue[@]}" -gt 0 ]; do
      front="${queue[0]}"
      queue=("${queue[@]:1}")
      cur="${front%%:*}" depth="${front##*:}"
      if [ "$cur" != "$fpid" ]; then
        cwd="$(readlink "/proc/$cur/cwd" 2>/dev/null || true)"
        if [ -n "$cwd" ]; then
          rcwd="$(realpath -m "$cwd" 2>/dev/null || printf '%s' "$cwd")"
          if [ "$rcwd" = "$target" ]; then
            cmdline="$(tr '\0' ' ' <"/proc/$cur/cmdline" 2>/dev/null || true)"
            case "$cmdline" in
              *opencode* | *herdr*)
                foot_addr_of "$fpid" >/dev/null && { best_foot="$fpid"; best_depth=0; break 2; } ;;
            esac
            if [ "$depth" -lt "$best_depth" ]; then
              best_foot="$fpid" best_depth="$depth"
            fi
          fi
        fi
      fi
      for child in ${children[$cur]:-}; do
        case "$visited" in *" $child "*) continue ;; esac
        visited+="$child "
        queue+=("$child:$((depth + 1))")
      done
    done
  done

  if [ -n "$best_foot" ]; then
    focus_foot "$(foot_addr_of "$best_foot")"
    exit 0
  fi
fi

exit 0
