#!/bin/bash
# Install / restart the rexec watcher. Run in a VNC terminal:
#   first time:  bash ~/setup_watcher.sh
#   restart:     bash ~/jobs/setup_watcher.sh
set -e
J="$HOME/jobs"
mkdir -p "$J"/inbox "$J"/outbox "$J"/work "$J"/archive
chmod 700 "$J"

# Files uploaded by "rexec.py init" land in the FTP root (= home); move them into ~/jobs.
self="$(readlink -f "$0")"
for pair in "rexec_watcher.py:watcher.py" "rexec.key:rexec.key" "setup_watcher.sh:setup_watcher.sh"; do
    src="$HOME/${pair%%:*}"; dst="$J/${pair##*:}"
    [ -f "$src" ] || continue
    [ "$(readlink -f "$dst")" = "$self" ] && continue   # never overwrite the script being executed
    cp -f "$src" "$dst" && rm -f "$src"
done
[ -f "$J/watcher.py" ] || { echo "ERROR: $J/watcher.py missing, run 'python remote_exec.py init' locally first"; exit 1; }
[ -f "$J/rexec.key" ] || { echo "ERROR: $J/rexec.key missing, run 'python remote_exec.py init' locally first"; exit 1; }
chmod 600 "$J/rexec.key"
command -v python3.11 >/dev/null || { echo "ERROR: python3.11 not found"; exit 1; }
command -v tmux >/dev/null || { echo "ERROR: tmux not found"; exit 1; }

tmux kill-session -t rexec 2>/dev/null || true
sleep 1
tmux new-session -d -s rexec \
    "while true; do python3.11 '$J/watcher.py'; rc=\$?; [ \$rc -eq 3 ] && break; echo \"watcher exited (\$rc), restarting in 5s\"; sleep 5; done; exec bash"
sleep 3
tail -n 5 "$J/watcher.log" 2>/dev/null || true
if [ -f "$J/outbox/heartbeat.json" ]; then
    echo "OK: rexec watcher is running in tmux session 'rexec' (view: tmux attach -t rexec, detach: Ctrl-b d)"
else
    echo "WARNING: no heartbeat yet, check: tmux attach -t rexec"
fi
