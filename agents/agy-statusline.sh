#!/usr/bin/env python3
"""
==============================================================================
AGY (Antigravity CLI) Custom Statusline Renderer
==============================================================================

Overview:
  Renders a real-time, responsive two-sided status bar in the Antigravity CLI (agy).
  - Left side : Brand (AGY/AGY(B)) · Model name + Permission ([yolo]) + Mode ([plan]/[edit])
  - Right side: Quotas (Gemini 5h & Weekly, Argon/Latest, 3P) with recharge countdowns + Context usage

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

Features:
  - Weekly Quota Reset Countdown: Formats weekly recharge countdown (e.g. 3d18h / 3d).
  - Multi-Quota Support: Tracks Gemini 5h & Weekly, Argon (Next-Gen/Latest), and 3P models.
  - Dim/Faint Styling (\\033[2m): Renders countdowns and delimiters in subtle dim text.
  - Responsive Width Adaptation: Automatically compresses or collapses labels and times
    to guarantee the status line never wraps or breaks on narrow terminals.
==============================================================================
"""

import sys
import json
import unicodedata
import re
import os
import shutil
from datetime import datetime, timezone


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


def get_color(pct: int) -> str:
    if pct >= 50:
        return "\033[32m"  # Green
    elif pct >= 20:
        return "\033[33m"  # Yellow
    return "\033[31m"  # Red


def get_reset_secs(q_item: dict) -> int:
    """Extract remaining reset countdown in seconds."""
    if not q_item:
        return 0
    secs = q_item.get("reset_in_seconds", 0)
    if secs and secs > 0:
        return int(secs)
    rt = q_item.get("reset_time")
    if rt:
        try:
            dt = datetime.fromisoformat(rt.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            diff = int((dt - now).total_seconds())
            return max(0, diff)
        except Exception:
            pass
    return 0


def fmt_time(secs: int, mode: str = "full") -> str:
    """Format seconds into concise countdown string."""
    if not secs or secs <= 0 or mode == "none":
        return ""
    d = secs // 86400
    h = (secs % 86400) // 3600
    m = (secs % 3600) // 60
    if mode == "compact":
        if d > 0:
            return f"{d}d"
        if h > 0:
            return f"{h}h"
        return f"{m}m"
    # full mode
    if d > 0:
        return f"{d}d{h}h" if h > 0 else f"{d}d"
    if h > 0:
        return f"{h}h{m}m" if m > 0 else f"{h}h"
    return f"{m}m"


def main():
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return
        data = json.loads(raw)
    except Exception:
        return

    # Terminal width detection
    term_width = data.get("terminal_width")
    if not term_width or term_width <= 0:
        term_width = shutil.get_terminal_size((80, 20)).columns

    model_info = data.get("model") or {}
    raw_model_name = model_info.get("display_name") or model_info.get("id") or "AGY"

    # Working / Cycle Mode
    raw_cycle_mode = str(data.get("cycle_mode") or "").lower()
    raw_mode = str(data.get("mode") or data.get("agent_mode") or "").lower()
    all_mode_str = f"{raw_cycle_mode} {raw_mode}".strip()

    is_yolo = check_yolo_mode_from_proc() or any(
        k in all_mode_str
        for k in ["solo", "yolo", "danger", "skip-perm", "bypass-review", "autonomous"]
    )

    mode_text = ""
    mode_color = ""
    mode_icon = ""
    if "plan" in all_mode_str:
        mode_text = "plan"
        mode_color = "\033[34m"
        mode_icon = "🎯"
    elif "ask-edits" in all_mode_str:
        mode_text = "edit:ask"
        mode_color = "\033[33m"
        mode_icon = "✍️"
    elif "accept-edits" in all_mode_str or "edit" in all_mode_str:
        mode_text = "edit"
        mode_color = "\033[33m"
        mode_icon = "✍️"
    elif raw_cycle_mode and raw_cycle_mode not in ["bypass-review", "accept-edits"]:
        mode_text = raw_cycle_mode
        mode_color = "\033[2m"
        mode_icon = "⚙️"

    is_agyb = (
        os.environ.get("USER") == "agyb"
        or "agyb" in os.environ.get("HOME", "")
        or (len(sys.argv) > 0 and "agyb" in sys.argv[0])
    )
    brand = "AGY(B)" if is_agyb else "AGY"

    quota = data.get("quota") or {}
    ctx = data.get("context_window") or {}
    used_pct = ctx.get("used_percentage")

    # Progressive adaptation ladder for small / wide terminals
    strategies = [
        # (time_mode, show_3p_wk, model_mode, effort, tags, sep, minimal)
        ("full",    True,  "full",  True,  "full",    "normal",  False),
        ("full",    False, "full",  True,  "full",    "compact", False),
        ("full",    False, "clean", True,  "full",    "compact", False),
        ("full",    False, "clean", False, "full",    "compact", False),
        ("compact", False, "clean", False, "full",    "compact", False),
        ("compact", False, "clean", False, "compact", "tight",   False),
        ("none",    False, "clean", False, "compact", "tight",   False),
        ("none",    False, "clean", False, "compact", "tight",   True),
    ]

    selected_line = ""
    for time_mode, show_3p_wk, model_mode, effort, tags, sep_style, minimal in strategies:
        # 1. Model Name
        m_name = raw_model_name
        if model_mode == "clean":
            m_name = m_name.replace("Gemini ", "").replace("Claude ", "")
        if not effort:
            m_name = re.sub(r"\s*\([^)]*\)", "", m_name)

        # 2. Left side: Brand + Model + [yolo] + [mode]
        if tags == "compact":
            yolo_tag = "\033[35m🚀 yolo\033[0m" if is_yolo else ""
            mode_tag = f"{mode_color}{mode_icon} {mode_text}\033[0m" if mode_text else ""
            left_sep = " "
        else:
            yolo_tag = "\033[35m🚀 [yolo]\033[0m" if is_yolo else ""
            mode_tag = f"{mode_color}{mode_icon} [{mode_text}]\033[0m" if mode_text else ""
            left_sep = "  "

        left_items = [f"\033[36m{brand} · {m_name}\033[0m"]
        if yolo_tag:
            left_items.append(yolo_tag)
        if mode_tag:
            left_items.append(mode_tag)
        left = left_sep.join(left_items)

        # 3. Quotas
        # Gemini 5h & Weekly
        g_parts = []
        g_5h = quota.get("gemini-5h")
        if g_5h and "remaining_fraction" in g_5h:
            pct_5h = int(round(g_5h["remaining_fraction"] * 100))
            c_5h = get_color(pct_5h)
            t_5h = fmt_time(get_reset_secs(g_5h), time_mode)
            t_str = f" \033[2m({t_5h})\033[0m" if t_5h else ""
            g_parts.append(f"{c_5h}5h: {pct_5h}%\033[0m{t_str}")

        g_wk = quota.get("gemini-weekly")
        if g_wk and "remaining_fraction" in g_wk:
            pct_wk = int(round(g_wk["remaining_fraction"] * 100))
            c_wk = get_color(pct_wk)
            t_wk = fmt_time(get_reset_secs(g_wk), time_mode)
            t_str = f" \033[2m({t_wk})\033[0m" if t_wk else ""
            g_parts.append(f"{c_wk}Wk: {pct_wk}%\033[0m{t_str}")

        gemini_str = f"⚡ {' '.join(g_parts)}" if g_parts else ""

        # Latest Model (Argon / WTU weekly)
        argon_str = ""
        if not minimal:
            argon_q = quota.get("gemini-argon-wtu-weekly") or next(
                (v for k, v in quota.items() if "argon" in k), None
            )
            if argon_q and "remaining_fraction" in argon_q:
                pct_ar = int(round(argon_q["remaining_fraction"] * 100))
                c_ar = get_color(pct_ar)
                t_ar = fmt_time(get_reset_secs(argon_q), time_mode)
                t_str = f" \033[2m({t_ar})\033[0m" if t_ar else ""
                lbl = "Arg" if tags == "compact" else "Argon"
                argon_str = f"{c_ar}{lbl}: {pct_ar}%\033[0m{t_str}"

        # Third-party Model (3P: 5h and weekly)
        p3_str = ""
        if not minimal:
            p3_5h = quota.get("3p-5h")
            p3_wk = quota.get("3p-weekly")
            p3_parts = []
            if p3_5h and "remaining_fraction" in p3_5h:
                pct_3p = int(round(p3_5h["remaining_fraction"] * 100))
                c_3p = get_color(pct_3p)
                t_3p = fmt_time(get_reset_secs(p3_5h), time_mode)
                t_str = f" \033[2m({t_3p})\033[0m" if t_3p else ""
                p3_parts.append(f"{c_3p}3P: {pct_3p}%\033[0m{t_str}")
            if show_3p_wk and p3_wk and "remaining_fraction" in p3_wk:
                pct_3pwk = int(round(p3_wk["remaining_fraction"] * 100))
                c_3pwk = get_color(pct_3pwk)
                t_3pwk = fmt_time(get_reset_secs(p3_wk), time_mode)
                t_str = f" \033[2m({t_3pwk})\033[0m" if t_3pwk else ""
                p3_parts.append(f"{c_3pwk}Wk: {pct_3pwk}%\033[0m{t_str}")
            p3_str = " ".join(p3_parts)

        # Context Usage
        ctx_str = ""
        if used_pct is not None:
            if tags == "compact":
                ctx_str = f"\033[35m📊 {used_pct:.0f}%\033[0m"
            else:
                ctx_str = f"\033[35m📊 Ctx: {used_pct:.1f}%\033[0m"

        right_items = [s for s in [gemini_str, argon_str, p3_str, ctx_str] if s]
        if sep_style == "normal":
            sep = "  \033[2m|\033[0m  "
        elif sep_style == "compact":
            sep = " \033[2m|\033[0m "
        else:
            sep = " "
        right = sep.join(right_items)

        l_len = str_width(left)
        r_len = str_width(right)
        total = l_len + 1 + r_len
        if total <= term_width:
            pad = max(1, term_width - l_len - r_len)
            selected_line = f"{left}{' ' * pad}{right}"
            break
        pad = max(1, term_width - l_len - r_len)
        selected_line = f"{left}{' ' * pad}{right}"

    print(selected_line)


if __name__ == "__main__":
    main()
