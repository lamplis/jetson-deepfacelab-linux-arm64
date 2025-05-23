#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────
# setup_env.sh
#
# Set up a virtual Python environment for DeepFaceLab on Jetson.
# Installs Python packages using a local wheel cache and allows
# a clean setup using the --clean flag.
#───────────────────────────────────────────────────────────────

set -xuo pipefail

#───────────────────────────────────────────────────────────────
# Configuration
#───────────────────────────────────────────────────────────────
ENV_NAME="dfl-arm64-venv"
PYTHON_VERSION="3.10"
PIP_INDEX_URL="https://pypi.jetson-ai-lab.dev/jp6/cu130/+simple"
EXTRA_INDEX_URL="https://pypi.org/simple"
CACHE_DIR="$HOME/.cache/dfl_wheels"
WHEEL_URLS=(
    "https://developer.download.nvidia.com/compute/redist/jp/v61/tensorflow/tensorflow-2.16.1+nv24.08-cp310-cp310-linux_aarch64.whl"
    "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/e6d/a8e91fd7e5f79/opencv_python-4.11.0-py3-none-any.whl"
)
# "https://pypi.jetson-ai-lab.dev/root/pypi/+f/541/a418b98b28df5/jaxlib-0.6.0-cp310-cp310-manylinux2014_aarch64.whl"
# "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/311/d1539318c172c/tensorflow-2.18.0-cp310-cp310-linux_aarch64.whl"
# https://developer.download.nvidia.com/compute/redist/jp/v61/tensorflow/tensorflow-2.16.1+nv24.08-cp310-cp310-linux_aarch64.whl
# https://developer.download.nvidia.com/compute/redist/jp/v61/pytorch/torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64.whl
# "https://pypi.jetson-ai-lab.dev/root/pypi/+f/2b3/9293cae3aeee5/tensorflow-2.19.0-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
# "https://pypi.jetson-ai-lab.dev/root/pypi/+f/c9a/fea41b11e1a1a/torch-2.7.0-cp310-cp310-manylinux_2_28_aarch64.whl"
# "https://developer.download.nvidia.com/compute/redist/jp/v61/pytorch/torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64.whl"
# "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/190/d8dfbcf6c4d3c/cupy-14.0.0a1-cp310-cp310-linux_aarch64.whl"
# 
#───────────────────────────────────────────────────────────────
# Parse optional flags
#───────────────────────────────────────────────────────────────
CLEAN_INSTALL=false
if [[ "${1:-}" == "--clean" ]]; then
  CLEAN_INSTALL=true
fi

#───────────────────────────────────────────────────────────────
# Clean system cache if requested
#───────────────────────────────────────────────────────────────
if $CLEAN_INSTALL; then
  echo "🧹 Performing full clean of environment and caches..."
  rm -rf "*-venv"
#### rm -rf "$CACHE_DIR" #Not redownloading WHEELS
  rm -rf ~/.cache/pip ~/.config/pip ~/.local/lib/python$PYTHON_VERSION
  find . -type d -name "__pycache__" -exec rm -rf {} +
  sudo apt clean
  echo "✅ Clean complete."
fi

#───────────────────────────────────────────────────────────────
# Install system requirements
#───────────────────────────────────────────────────────────────
echo "📦 Installing system dependencies..."
#### sudo apt update
sudo apt install -y \
  python3-venv python3-pip libatlas-base-dev hdf5-tools \
  qtbase5-dev qttools5-dev-tools qtdeclarative5-dev libqt5svg5-dev libqt5websockets5-dev libqt5x11extras5-dev

#───────────────────────────────────────────────────────────────
# Set up Python virtual environment
#───────────────────────────────────────────────────────────────
if [[ -d "$ENV_NAME" ]]; then
  echo "🔄 Removing existing virtual environment: $ENV_NAME"
  rm -rf "$ENV_NAME"
fi

echo "📦 Creating virtual environment: $ENV_NAME"
python3 -m venv "$ENV_NAME"
source "$ENV_NAME/bin/activate"

#───────────────────────────────────────────────────────────────
# Configure pip index
#───────────────────────────────────────────────────────────────
echo "⚙️ Setting up pip configuration with Jetson AI Lab index..."
mkdir -p "$HOME/.config/pip"
cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index-url = $PIP_INDEX_URL
EOF
# extra-index-url = https://pypi.org/simple
echo "✅ pip configuration written to: $HOME/.config/pip/pip.conf"

#───────────────────────────────────────────────────────────────
# Download wheels and dependencies to cache
#───────────────────────────────────────────────────────────────
mkdir -p "$CACHE_DIR"

# PyQt5 version you need
PYQT_VERSION="5.15.11"

# If we haven’t yet built the wheel, do so now
if ! ls "$CACHE_DIR"/PyQt5-"$PYQT_VERSION"*linux_aarch64.whl &>/dev/null; then
  echo "🛠️  Building PyQt5 wheel v$PYQT_VERSION (one-time)…"

  # Build the wheel into our cache
##  python3 -m pip wheel --no-deps --wheel-dir "$CACHE_DIR" \
##  "PyQt5==$PYQT_VERSION"

  echo "✅ PyQt5 wheel built and cached in $CACHE_DIR."
else
  echo "✅ Found existing PyQt5 wheel in cache, skipping rebuild."
fi

echo "📦 Preloading wheels and dependencies to cache..."

for url in "${WHEEL_URLS[@]}"; do
  filename=$(basename "$url")
  dest="$CACHE_DIR/$filename"
  if [[ ! -f "$dest" ]]; then
    echo "⬇️  Downloading $filename..."
    wget -q --show-progress -O "$dest" "$url"
  else
    echo "✅ Using cached $filename"
  fi

  echo "📥 Resolving dependencies for: $filename"
  python3 -m pip download \
    --dest "$CACHE_DIR" \
    --no-deps \
    --only-binary=:all: \
    "$dest"
done

#───────────────────────────────────────────────────────────────
# Install all cached wheels
#───────────────────────────────────────────────────────────────
echo "📦 Installing additional packages from requirements file: requirements-jetson.txt......................"
# --extra-index-url "$EXTRA_INDEX_URL" \
python3 -m pip install \
  ${CLEAN_INSTALL:+--no-cache-dir} \
  --force-reinstall \
  -r "requirements-jetson.txt"  || true
  
echo "📥 Installing cached wheel files............................................................................"
python3 -m pip install \
  ${CLEAN_INSTALL:+--no-cache-dir} \
  --force-reinstall \
  "$CACHE_DIR"/*.whl

echo "📥 Fix jax incompatibility..."
#pip install --force-reinstall "numpy>=1.20,<1.24" "flatbuffers~=1.12" #"jax<=0.4.13" "ml-dtypes<=0.2.0"  || true
#python3 -m pip uninstall tf2onnx protobuf -y
 
#python3 -m pip install --force-reinstall "tf2onnx==1.9.3" #colorama #"tf2onnx==1.9.3"
python3 -m pip install --force-reinstall "numpy>=1.20,<1.24" # "protobuf<5.0" "protobuf<5.0" "flatbuffers>=23.5.26"
#pip3 install --force-reinstall "PyQt5<5.15" pyqt5-sip
python3 -m pip uninstall jax
#───────────────────────────────────────────────────────────────
# ✅ Post-install verification: TensorFlow GPU support on Jetson
#───────────────────────────────────────────────────────────────

echo "🔍 Verifying TensorFlow GPU compatibility..."

python3 - <<'EOF'
import os
import sys
import tensorflow as tf
import torch
import cupy

print("📦 TensorFlow version:", tf.__version__)
gpu_devices = tf.config.list_physical_devices('GPU')

if not gpu_devices:
    print("❌ ERROR: No GPU device detected by TensorFlow.")
    print("💡 Tip: Ensure you're using a Jetson-compatible TensorFlow wheel (e.g., 2.18.0).")
    print("🔗 Check available versions at: https://pypi.jetson-ai-lab.dev/jp6/cu126")
    sys.exit(1)
else:
    print(f"✅ GPU detected: {gpu_devices[0].name}")

print("✔️ torch version:", torch.__version__)
assert torch.cuda.is_available(), "❌ PyTorch did not detect CUDA!"

print("✔️ cupy version:", cupy.__version__)
dev = cupy.cuda.Device()
print("✔️ cupy CUDA device:", dev)

# Check for known TensorFlow ops
try:
    print("🧪 Checking OpenCV + cv2 interoperability...")
    import cv2
    print("📷 OpenCV version:", getattr(cv2, '__version__', 'unknown'))
    print("🔁 cv2.INTER_CUBIC value:", cv2.INTER_CUBIC)
except Exception as e:
    print("⚠️ OpenCV test failed:", str(e))
    sys.exit(1)
EOF

echo "✅ All GPU and library checks passed successfully."

#───────────────────────────────────────────────────────────────
# Final Output
#───────────────────────────────────────────────────────────────
echo "✅ Environment setup completed successfully."
echo "💡 To activate this environment later, run: source $ENV_NAME/bin/activate"

