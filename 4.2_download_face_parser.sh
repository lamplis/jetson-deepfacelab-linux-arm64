#!/usr/bin/env bash
source env.sh

mkdir -p "$DFL_SRC/model_face_parser"
wget -O "$DFL_SRC/model_face_parser/resnet18.onnx" \
    https://github.com/yakhyo/face-parsing/releases/download/weights/resnet18.onnx
