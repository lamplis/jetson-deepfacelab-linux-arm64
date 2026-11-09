#!/usr/bin/env bash
source env.sh

$DFL_PYTHON "$DFL_SRC/main.py" train \
    --training-data-src-dir "$DFL_WORKSPACE/data_src/aligned" \
    --training-data-dst-dir "$DFL_WORKSPACE/data_dst/aligned" \
    --pretraining-data-dir "$DFL_SRC/pretrain_CelebA" \
    --model-dir "$DFL_WORKSPACE/model" \
    --model AMP \
    --no-preview \
    --config-training-file "$DFL_WORKSPACE/model" \
    --saving-time 60 \
    --silent-start \
    --tensorboard-logdir "$DFL_WORKSPACE/logs"