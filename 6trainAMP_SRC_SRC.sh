#!/usr/bin/env bash
source env.sh

$DFL_PYTHON "$DFL_SRC/main.py" train \
    --training-data-src-dir "$DFL_WORKSPACE/data_src/aligned" \
    --training-data-dst-dir "$DFL_WORKSPACE/data_src/aligned" \
    --pretraining-data-dir "$DFL_SRC/pretrain_CelebA" \
    --model-dir "$DFL_WORKSPACE/model" \
    --model AMP \
    --saving-time 60 \
    --no-preview
#    --silent-start 

#    
