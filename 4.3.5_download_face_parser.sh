#!/usr/bin/env bash
source env.sh

mkdir -p "$DFL_SRC/model_face_parser"
wget -O "$DFL_SRC/model_face_parser/resnet34.onnx" \
    https://github.com/yakhyo/face-parsing/releases/download/weights/resnet34.onnx
