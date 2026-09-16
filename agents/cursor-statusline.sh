#!/usr/bin/env python3
"""
==============================================================================
Cursor CLI Custom Statusline Renderer
==============================================================================

Overview:
  Same two-sided bar as agents/agy-statusline.sh, for `cursor-agent`.
  - Left side : Model name + Permission state ([yolo]) + Cycle mode ([plan]/[edit])
  - Right side: Quotas (Auto + API remaining) + Context window usage (%)

Usage:
  1. Link to Cursor config:
     ln -sf ~/Projects/dotfiles/agents/cursor-statusline.sh ~/.cursor/statusline.sh

  2. Merge into the cli-config.json that cursor-agent actually loads
     ($XDG_CONFIG_HOME/cursor/cli-config.json when XDG_CONFIG_HOME is set):
     {
       "statusLine": {
         "type": "command",
         "command": "~/.cursor/statusline.sh",
         "padding": 2
       }
     }

  3. Restart the CLI session.

How it works:
  1. Input: Cursor pipes a session JSON object to stdin on each update.
  2. YOLO Detection: Inspects /proc/<pid>/cmdline up the process tree for
     --yolo / --force (same idea as AGY --dangerously-skip-permissions).
  3. Quota: POSTs GetCurrentPeriodUsage (cached 60s). Not a model call;
     it does not consume conversation tokens.
  4. Right Alignment: Computes terminal column width and visible text lengths
     (accounting for wide Unicode emojis) to dynamically push quotas to the right.
==============================================================================
"""

import json
import os
import re
import shutil
import sys
import tempfile
import time
import unicodedata
import urllib.error
import urllib.request

CACHE_TTL_SEC = 60
USAGE_URL = "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
AUTH_CANDIDATES = (
    os.environ.get("CURSOR_AUTH_FILE"),
    os.path.expanduser("~/.config/cursor/auth.json"),
    os.path.expanduser("~/.cursor/auth.json"),
)


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


def iter_parent_cmdlines():
    pid = os.getppid()
    while pid > 1:
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                yield f.read().decode("utf-8", errors="ignore").replace("\x00", " ")
            with open(f"/proc/{pid}/stat", "r") as f:
                pid = int(f.read().split()[3])
        except Exception:
            break


def check_yolo_mode_from_proc() -> bool:
    """Check if cursor-agent was launched with --yolo / --force."""
    for cmd in iter_parent_cmdlines():
        if any(
            k in cmd
            for k in [
                "dangerously-skip-permissions",
                "skip-permissions",
                "--yolo",
                "--force",
                "--solo",
            ]
        ):
            return True
    return False


def cycle_mode_from_proc() -> str:
    """Detect --mode plan / --mode ask / --plan from the process tree."""
    for cmd in iter_parent_cmdlines():
        if " --mode plan" in f" {cmd}" or " --plan" in f" {cmd}":
            return "plan"
        if " --mode ask" in f" {cmd}":
            return "ask"
    return ""


def cache_path() -> str:
    override = os.environ.get("CURSOR_STATUSLINE_CACHE")
    if override:
        return override
    root = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return os.path.join(root, "cursor-statusline-usage.json")


def parse_epoch(value) -> int:
    if value in (None, "", 0):
        return 0
    try:
        n = int(value)
    except (TypeError, ValueError):
        return 0
    if n > 10_000_000_000:
        n //= 1000
    return n


def remaining_pct(used):
    if used is None or used == "":
        return None
    try:
        used_f = float(used)
    except (TypeError, ValueError):
        return None
    return int(round(max(0.0, min(100.0, 100.0 - used_f))))


def read_access_token() -> str:
    for path in AUTH_CANDIDATES:
        if not path or not os.path.isfile(path):
            continue
        try:
            with open(path, encoding="utf-8") as f:
                token = (json.load(f) or {}).get("accessToken") or ""
        except Exception:
            continue
        if token:
            return token
    return ""


def read_json_file(path: str):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def cache_is_fresh(path: str) -> bool:
    try:
        return (time.time() - os.path.getmtime(path)) < CACHE_TTL_SEC
    except OSError:
        return False


def fetch_usage(token: str):
    req = urllib.request.Request(
        USAGE_URL,
        data=b"{}",
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            body = json.load(resp)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None
    if not isinstance(body, dict) or not isinstance(body.get("planUsage"), dict):
        return None
    return body


def write_cache(path: str, data: dict) -> None:
    directory = os.path.dirname(path) or "."
    os.makedirs(directory, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix="cursor-statusline-", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def load_usage() -> dict:
    path = cache_path()
    cached = read_json_file(path) if os.path.isfile(path) else None
    if cache_is_fresh(path) and isinstance(cached, dict):
        return cached

    token = read_access_token()
    if not token:
        return cached if isinstance(cached, dict) else {}

    fresh = fetch_usage(token)
    if fresh:
        write_cache(path, fresh)
        return fresh
    return cached if isinstance(cached, dict) else {}


def main():
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return
        data = json.loads(raw)
    except Exception:
        return

    # Terminal width detection (fallback to terminal size or 80 cols)
    term_width = data.get("terminal_width") or data.get("render_width_chars")
    if not term_width or term_width <= 0:
        term_width = shutil.get_terminal_size((80, 20)).columns

    model_info = data.get("model") or {}
    model_name = model_info.get("display_name") or model_info.get("id") or "Cursor"

    # Raw mode fields from payload (and Cursor CLI argv)
    raw_cycle_mode = str(
        data.get("cycle_mode") or cycle_mode_from_proc() or ""
    ).lower()
    raw_mode = str(data.get("mode") or data.get("agent_mode") or "").lower()
    all_mode_str = f"{raw_cycle_mode} {raw_mode}".strip()

    # 1. Permission State (YOLO)
    is_yolo = (
        check_yolo_mode_from_proc()
        or bool(data.get("autorun"))
        or any(
            k in all_mode_str
            for k in ["solo", "yolo", "danger", "skip-perm", "bypass-review", "autonomous"]
        )
    )
    yolo_tag = "\033[35m🚀 [yolo]\033[0m" if is_yolo else ""

    # 2. Cycle / Working Mode State (plan / edit / edit:ask)
    mode_tag = ""
    if "plan" in all_mode_str:
        mode_tag = "\033[34m🎯 [plan]\033[0m"
    elif "ask-edits" in all_mode_str or all_mode_str.strip() == "ask":
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
        d = secs // 86400
        h = (secs % 86400) // 3600
        m = (secs % 3600) // 60
        if d > 0:
            return f"{d}d{h}h"
        if h > 0:
            return f"{h}h{m}m"
        return f"{m}m"

    usage = load_usage()
    plan = usage.get("planUsage") or {}
    right_parts = []

    # Auto (included) + API, same layout as AGY 5h + Wk
    auto_rem = remaining_pct(plan.get("autoPercentUsed"))
    if auto_rem is not None:
        c_auto = get_color(auto_rem)
        reset_at = parse_epoch(usage.get("billingCycleEnd"))
        t_auto = fmt_time(reset_at - int(time.time())) if reset_at else ""
        t_str = f" \033[2m({t_auto})\033[0m" if t_auto else ""

        api_rem = remaining_pct(plan.get("apiPercentUsed"))
        api_str = ""
        if api_rem is not None:
            c_api = get_color(api_rem)
            api_str = f"  {c_api}API: {api_rem}%\033[0m"

        right_parts.append(f"{c_auto}⚡ Auto: {auto_rem}%\033[0m{t_str}{api_str}")

    # Context usage (always show, same slot as AGY)
    ctx = data.get("context_window") or {}
    used_pct = ctx.get("used_percentage")
    try:
        ctx_val = 0.0 if used_pct is None else float(used_pct)
        right_parts.append(f"\033[35m📊 Ctx: {ctx_val:.1f}%\033[0m")
    except (TypeError, ValueError):
        right_parts.append("\033[35m📊 Ctx: 0.0%\033[0m")

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
