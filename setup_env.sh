#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────
# setup_env.sh
#
# Set up a virtual Python environment for DeepFaceLab on Jetson.
# Installs Python packages using a local wheel cache and allows
# a clean setup using the --clean flag.
#───────────────────────────────────────────────────────────────

set -euo pipefail

#───────────────────────────────────────────────────────────────
# Configuration
#───────────────────────────────────────────────────────────────
ENV_NAME="dfl-arm"
PYTHON_VERSION="3.10"
PIP_INDEX_URL="https://pypi.jetson-ai-lab.dev/jp6/cu130/+simple"
EXTRA_INDEX_URL="https://pypi.org/simple"
CACHE_DIR="$HOME/.cache/dfl_wheels"
WHEEL_URLS=(
  "https://pypi.jetson-ai-lab.dev/jp6/cu128/+f/395/7b5d0bec560ae/opencv_python-4.11.0-py3-none-any.whl"
  "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/6ef/f643c0a7acda9/torch-2.7.0-cp310-cp310-linux_aarch64.whl"
  "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/190/d8dfbcf6c4d3c/cupy-14.0.0a1-cp310-cp310-linux_aarch64.whl"
  "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/5e2/8f3dca560ab6f/jaxlib-0.6.0.dev20250414-cp310-cp310-manylinux2014_aarch64.whl"
)
# "https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/311/d1539318c172c/tensorflow-2.18.0-cp310-cp310-linux_aarch64.whl"
# https://developer.download.nvidia.com/compute/redist/jp/v61/tensorflow/tensorflow-2.16.1+nv24.08-cp310-cp310-linux_aarch64.whl
# https://developer.download.nvidia.com/compute/redist/jp/v61/pytorch/torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64.whl

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
  rm -rf "$ENV_NAME"
  rm -rf "$CACHE_DIR"
  rm -rf ~/.cache/pip ~/.config/pip ~/.local/lib/python$PYTHON_VERSION
  find . -type d -name "__pycache__" -exec rm -rf {} +
  sudo apt clean
  echo "✅ Clean complete."
fi

#───────────────────────────────────────────────────────────────
# Install system requirements
#───────────────────────────────────────────────────────────────
echo "📦 Installing system dependencies..."
sudo apt update
sudo apt install -y python3-venv python3-pip libatlas-base-dev

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
echo "📥 Installing wheel files..."
python3 -m pip install \
  ${CLEAN_INSTALL:+--no-cache-dir} \
  --force-reinstall \
  "$CACHE_DIR"/*.whl


echo "📦 Installing additional packages from requirements file: requirements-jetson.txt"
# --extra-index-url "$EXTRA_INDEX_URL" \
python3 -m pip install \
  ${CLEAN_INSTALL:+--no-cache-dir} \
  -r "requirements-jetson.txt"
  
echo "📥 Installing wheel files..."
python3 -m pip install \
  ${CLEAN_INSTALL:+--no-cache-dir} \
  --force-reinstall \
  --only-binary=:all: \
  "$CACHE_DIR"/*.whl
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

