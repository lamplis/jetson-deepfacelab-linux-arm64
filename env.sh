#!/usr/bin/env bash
# Resolve paths from this file so the scripts work no matter the caller's cwd.
_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$_ENV_DIR"

export PATH="$HOME/miniconda3/envs/dfl-arm/bin:$PATH"
export DFL_PYTHON="${DFL_PYTHON:-$HOME/miniconda3/envs/dfl-arm/bin/python}"
export DFL_WORKSPACE="${DFL_WORKSPACE:-$_ENV_DIR/workspace}"

if [ ! -d "$DFL_WORKSPACE" ]; then
    mkdir -p "$DFL_WORKSPACE" \
        "$DFL_WORKSPACE/data_src/aligned" \
        "$DFL_WORKSPACE/data_src/aligned_debug" \
        "$DFL_WORKSPACE/data_dst/aligned" \
        "$DFL_WORKSPACE/data_dst/aligned_debug" \
        "$DFL_WORKSPACE/model" \
        "$DFL_WORKSPACE/logs"
fi

export DFL_ROOT="$_ENV_DIR/"
export DFL_SRC="$_ENV_DIR/_internal/DeepFaceLab"

# A second trainer on this Orin exhausts GPU memory. Call this only from train scripts.
dfl_stop_previous_trainer() {
    local pids pid pgid i
    pids=$(pgrep -f "[m]ain.py train" || true)
    if [ -z "$pids" ]; then
        return 0
    fi
    echo "Stopping the trainer already running."
    for pid in $pids; do
        pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')
        if [ -n "$pgid" ] && [ "$pgid" != "$$" ]; then
            kill -TERM -- "-$pgid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
        else
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    for i in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -f "[m]ain.py train" >/dev/null 2>&1 || return 0
        sleep 0.5
    done
    pids=$(pgrep -f "[m]ain.py train" || true)
    for pid in $pids; do
        pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')
        if [ -n "$pgid" ] && [ "$pgid" != "$$" ]; then
            kill -KILL -- "-$pgid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        else
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
}
