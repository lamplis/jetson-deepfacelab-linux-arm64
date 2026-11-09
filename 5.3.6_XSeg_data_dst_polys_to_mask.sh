#!/usr/bin/env bash
source env.sh

$DFL_PYTHON "$DFL_SRC/main.py" xseg polys_to_mask \
    --input-dir "$DFL_WORKSPACE/data_dst/aligned"
