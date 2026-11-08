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
