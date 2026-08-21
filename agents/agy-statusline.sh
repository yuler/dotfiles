#!/usr/bin/env python3
"""
==============================================================================
AGY (Antigravity CLI) Custom Statusline Renderer
==============================================================================

Overview:
  Renders a real-time, two-sided status bar in the Antigravity CLI (agy).
  - Left side : Model name + Permission state ([yolo]) + Cycle mode ([plan]/[edit])
  - Right side: Quotas (5h sliding window + weekly) + Context window usage (%)

Usage:
  1. Link to your AGY configuration:
     ln -sf ~/Projects/dotfiles/agents/agy-statusline.sh ~/.gemini/antigravity-cli/statusline.sh

  2. Configure ~/.gemini/antigravity-cli/settings.json:
     {
       "statusLine": {
         "type": "command",
         "command": "~/.gemini/antigravity-cli/statusline.sh",
         "enabled": true
       }
     }

  3. Alternatively, toggle in an active session via slash command:
     /statusline ~/.gemini/antigravity-cli/statusline.sh

How it works:
  1. Input: agy pipes a session state JSON object to this script's stdin on
     every event loop update.
  2. YOLO Detection: Inspects /proc/<pid>/cmdline up the process tree to
     reliably detect if agy was launched with --dangerously-skip-permissions.
  3. Quota Extraction: Reads Gemini (gemini-5h, gemini-weekly) and 3P quotas,
     formatting remaining percentages and reset countdowns with color coding.
  4. Right Alignment: Computes terminal column width and visible text lengths
     (accounting for wide Unicode emojis) to dynamically push quotas to the right.
==============================================================================
"""

import sys
import json
import unicodedata
import re
import os
import shutil


def strip_ansi(s: str) -> str:
    """Strip ANSI color and formatting escape sequences."""
    return re.sub(r"\x1B\[[0-9;]*[a-zA-Z]", "", s)


def str_width(s: str) -> int:
    """Calculate the printable terminal column width of a string."""
    clean = strip_ansi(s)
    w = 0
    for c in clean:
        if unicodedata.east_asian_width(c) in ("W", "F") or ord(c) > 0x2000:
            w += 2
        else:
            w += 1
    return w


def check_yolo_mode_from_proc() -> bool:
    """Check if agy parent process was launched with --dangerously-skip-permissions."""
    pid = os.getppid()
    while pid > 1:
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                cmd = f.read().decode("utf-8", errors="ignore").replace("\x00", " ")
                if any(
                    k in cmd
                    for k in [
                        "dangerously-skip-permissions",
                        "skip-permissions",
                        "--yolo",
                        "--solo",
                    ]
                ):
                    return True
            with open(f"/proc/{pid}/stat", "r") as f:
                pid = int(f.read().split()[3])
        except Exception:
            break
    return False


def main():
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return
        data = json.loads(raw)
    except Exception:
        return

    # Terminal width detection (fallback to terminal size or 80 cols)
    term_width = data.get("terminal_width")
    if not term_width or term_width <= 0:
        term_width = shutil.get_terminal_size((80, 20)).columns

    model_info = data.get("model") or {}
    model_name = model_info.get("display_name") or model_info.get("id") or "AGY"

    # Raw mode fields from payload
    raw_cycle_mode = str(data.get("cycle_mode") or "").lower()
    raw_mode = str(data.get("mode") or data.get("agent_mode") or "").lower()
    all_mode_str = f"{raw_cycle_mode} {raw_mode}".strip()

    # 1. Permission State (YOLO)
    is_yolo = check_yolo_mode_from_proc() or any(
        k in all_mode_str
        for k in ["solo", "yolo", "danger", "skip-perm", "bypass-review", "autonomous"]
    )
    yolo_tag = "\033[35m🚀 [yolo]\033[0m" if is_yolo else ""

    # 2. Cycle / Working Mode State (plan / edit / edit:ask)
    mode_tag = ""
    if "plan" in all_mode_str:
        mode_tag = "\033[34m🎯 [plan]\033[0m"
    elif "ask-edits" in all_mode_str:
        mode_tag = "\033[33m✍️ [edit:ask]\033[0m"
    elif "accept-edits" in all_mode_str or "edit" in all_mode_str:
        mode_tag = "\033[33m✍️ [edit]\033[0m"
    elif raw_cycle_mode and raw_cycle_mode not in [
        "bypass-review",
        "accept-edits",
    ]:
        mode_tag = f"\033[2m⚙️ [{raw_cycle_mode}]\033[0m"

    # Assemble Left Side: Model + [yolo] + [plan/edit]
    left_items = [f"\033[36m🤖 {model_name}\033[0m"]
    if yolo_tag:
        left_items.append(yolo_tag)
    if mode_tag:
        left_items.append(mode_tag)
    left = "  ".join(left_items)

    # Quota helper functions
    def get_color(pct: int) -> str:
        if pct >= 50:
            return "\033[32m"  # Green
        elif pct >= 20:
            return "\033[33m"  # Yellow
        return "\033[31m"  # Red

    def fmt_time(secs: int) -> str:
        if not secs or secs <= 0:
            return ""
        h = secs // 3600
        m = (secs % 3600) // 60
        return f"{h}h{m}m" if h > 0 else f"{m}m"

    quota = data.get("quota") or {}
    right_parts = []

    # Gemini 5h & weekly quota
    g_5h = quota.get("gemini-5h")
    if g_5h and "remaining_fraction" in g_5h:
        pct_5h = int(round(g_5h["remaining_fraction"] * 100))
        c_5h = get_color(pct_5h)
        t_5h = fmt_time(g_5h.get("reset_in_seconds", 0))
        t_str = f" \033[2m({t_5h})\033[0m" if t_5h else ""

        g_wk = quota.get("gemini-weekly")
        wk_str = ""
        if g_wk and "remaining_fraction" in g_wk:
            pct_wk = int(round(g_wk["remaining_fraction"] * 100))
            c_wk = get_color(pct_wk)
            wk_str = f"  {c_wk}Wk: {pct_wk}%\033[0m"

        right_parts.append(f"{c_5h}⚡ 5h: {pct_5h}%\033[0m{t_str}{wk_str}")

    # 3P (Claude/Sonnet/etc.) quota
    p3_5h = quota.get("3p-5h")
    if p3_5h and any(
        k in model_name.lower() for k in ["claude", "3p", "sonnet", "haiku", "opus"]
    ):
        pct_3p = int(round(p3_5h.get("remaining_fraction", 0) * 100))
        c_3p = get_color(pct_3p)
        t_3p = fmt_time(p3_5h.get("reset_in_seconds", 0))
        t_str = f" \033[2m({t_3p})\033[0m" if t_3p else ""
        right_parts.append(f"{c_3p}⚡ 3P: {pct_3p}%\033[0m{t_str}")

    # Context usage
    ctx = data.get("context_window") or {}
    used_pct = ctx.get("used_percentage")
    if used_pct is not None:
        right_parts.append(f"\033[35m📊 Ctx: {used_pct:.1f}%\033[0m")

    right = "  |  ".join(right_parts)

    # Output with dynamic padding for right-alignment
    if right:
        l_len = str_width(left)
        r_len = str_width(right)
        pad = max(2, term_width - l_len - r_len)
        padding = " " * pad
        print(f"{left}{padding}{right}")
    else:
        print(left)


if __name__ == "__main__":
    main()
