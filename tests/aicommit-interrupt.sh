#!/usr/bin/env bash
# Ctrl+C on a controlling tty must stop aicommit and every agent it started.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AICOMMIT="$ROOT/bin/aicommit"
WORKDIR="$(mktemp -d)"
FAKEBIN="$(mktemp -d)"
MARKER="$WORKDIR/events.log"
export MARKER

cleanup() {
  if [[ -n "${AC_PID:-}" ]]; then
    kill -KILL -- -"$AC_PID" 2>/dev/null || true
    kill -KILL "$AC_PID" 2>/dev/null || true
  fi
  pkill -KILL -f "$FAKEBIN/" 2>/dev/null || true
  rm -rf "$WORKDIR" "$FAKEBIN"
}
trap cleanup EXIT

mkdir -p "$WORKDIR/.agents/skills/git-commit/scripts"
printf '# git-commit\n' >"$WORKDIR/.agents/skills/git-commit/SKILL.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"$WORKDIR/.agents/skills/git-commit/scripts/git-diff.sh"
chmod +x "$WORKDIR/.agents/skills/git-commit/scripts/git-diff.sh"

write_stubborn_agent() {
  local path="$1" name="$2"
  cat >"$path" <<EOF
#!/usr/bin/env bash
echo "${name}-start \$\$" >>"\$MARKER"
trap '' INT TERM
sleep 120
echo "${name}-end" >>"\$MARKER"
EOF
  chmod +x "$path"
}

write_stubborn_agent "$FAKEBIN/pi" pi
write_stubborn_agent "$FAKEBIN/opencode" opencode
write_stubborn_agent "$FAKEBIN/cursor-agent" cursor

cd "$WORKDIR"
git init -q
git config user.email test@example.com
git config user.name test
printf 'x\n' >file.txt
git add file.txt

export PATH="$FAKEBIN:/usr/bin:/bin"
export AICOMMIT_LOCK_FILE="$WORKDIR/aicommit.lock"
export AICOMMIT_AGENT_TIMEOUT=60
export HOME="$WORKDIR"

python3 - "$AICOMMIT" "$WORKDIR" "$MARKER" <<'PY'
import os, pty, select, sys, time, errno

aicommit, workdir, marker = sys.argv[1], sys.argv[2], sys.argv[3]
pid, fd = pty.fork()
if pid == 0:
    os.chdir(workdir)
    os.execv(aicommit, [aicommit])

deadline = time.time() + 5
while time.time() < deadline:
    if os.path.exists(marker):
        with open(marker) as f:
            if "pi-start" in f.read():
                break
    try:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            os.read(fd, 4096)
    except OSError:
        break
else:
    os.kill(pid, 9)
    sys.exit("FAIL: pi never started")

time.sleep(0.2)
os.write(fd, b"\x03")  # Ctrl+C on the pty

deadline = time.time() + 3
while time.time() < deadline:
    wpid, status = os.waitpid(pid, os.WNOHANG)
    if wpid != 0:
        open(os.path.join(workdir, "exit_status"), "w").write(str(status))
        break
    try:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            os.read(fd, 4096)
    except OSError:
        pass
else:
    os.kill(pid, 9)
    sys.exit("FAIL: aicommit still running after SIGINT")

open(os.path.join(workdir, "ac_pid"), "w").write(str(pid))
PY

sleep 0.4

if grep -q opencode-start "$MARKER"; then
  echo "FAIL: continued to opencode after interrupt"
  exit 1
fi
if grep -q cursor-start "$MARKER"; then
  echo "FAIL: continued to cursor-agent after interrupt"
  exit 1
fi
if grep -q pi-end "$MARKER"; then
  echo "FAIL: pi kept running after interrupt"
  exit 1
fi

pi_pid="$(awk '/pi-start/{print $2; exit}' "$MARKER")"
if [[ -n "$pi_pid" ]] && kill -0 "$pi_pid" 2>/dev/null; then
  echo "FAIL: pi pid $pi_pid still running after interrupt"
  exit 1
fi

echo PASS
