#!/usr/bin/env bash
source env.sh

$DFL_PYTHON "$DFL_SRC/main.py" xseg parse \
    --input-dir "$DFL_WORKSPACE/data_src/aligned" \
    --model-file "$DFL_SRC/model_face_parser/resnet18.onnx" \
    --inner-mouth include
