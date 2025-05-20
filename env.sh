#!/usr/bin/env bash
#conda activate dfl-arm64
cd ..
# -- Correct Python
export DFL_PYTHON="python3"

# -- Correct absolute paths
export DFL_WORKSPACE="$HOME/jetson-deepfacelab-linux-arm64/workspace"
export DFL_SRC="$HOME/jetson-deepfacelab-linux-arm64/_internal/DeepFaceLab"
export DFL_ROOT="$HOME/jetson-deepfacelab-linux-arm64"

# -- Create workspace folders if missing
if [ ! -d "$DFL_WORKSPACE" ]; then
    mkdir "$DFL_WORKSPACE"
    mkdir "$DFL_WORKSPACE/data_src"
    mkdir "$DFL_WORKSPACE/data_src/aligned"
    mkdir "$DFL_WORKSPACE/data_src/aligned_debug"
    mkdir "$DFL_WORKSPACE/data_dst"
    mkdir "$DFL_WORKSPACE/data_dst/aligned"
    mkdir "$DFL_WORKSPACE/data_dst/aligned_debug"
    mkdir "$DFL_WORKSPACE/model"
fi

# -- Check if /workspace/model is empty, if yes copy from /opt/model
if [ ! -d "$DFL_WORKSPACE/model" ] || [ -z "$(ls -A "$DFL_WORKSPACE/model")" ]; then
    mkdir -p "$DFL_WORKSPACE/model"
    #echo "📁 Copying default models from /opt/model to /workspace/model..."
    #cp -r /opt/model/* "$DFL_WORKSPACE/model/"
fi
