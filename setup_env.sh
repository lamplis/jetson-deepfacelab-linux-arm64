#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────
# setup_env.sh
#
# Set up a Python virtual environment for DeepFaceLab on Jetson
# - Adds NVIDIA FFmpeg repository (if missing)
# - Installs minimal system dependencies
# - Creates and activates a fresh Python venv
# - Configures pip with Jetson AI Lab index
# - Installs all required Python packages
#───────────────────────────────────────────────────────────────

set -euo pipefail

ENV_NAME="dfl-arm64-venv"
PYTHON_VERSION="3.10"
REQ_FILE="requirements-jetson.txt"
EXTRA_INDEX_URL="https://pypi.jetson-ai-lab.dev/jp6/cu126"
PIP_INDEX_URL="https://pypi.jetson-ai-lab.dev/jp6/cu126"
JETSON_REPO_FILE="/etc/apt/sources.list.d/jetson-ffmpeg.list"

#───────────────────────────────────────────────────────────────
# Step 1: Configure APT repository (NVIDIA Jetson FFmpeg)
#───────────────────────────────────────────────────────────────
echo "🔎 Checking for NVIDIA Jetson FFmpeg repository..."

if [[ ! -f "$JETSON_REPO_FILE" ]]; then
  echo "📥 Adding NVIDIA Jetson FFmpeg repository to APT..."
  sudo tee "$JETSON_REPO_FILE" > /dev/null <<EOF
deb https://repo.download.nvidia.com/jetson/ffmpeg main main
deb-src https://repo.download.nvidia.com/jetson/ffmpeg main main
EOF
else
  echo "✅ NVIDIA FFmpeg repository already configured at $JETSON_REPO_FILE"
fi

#───────────────────────────────────────────────────────────────
# Step 2: Install required system dependencies
#───────────────────────────────────────────────────────────────
echo "🔄 Updating APT cache..."
#sudo apt update

echo "🛠️ Updating CA Certificates..."
sudo apt install --only-upgrade ca-certificates


echo "📦 Installing system packages: python3-venv, python3-pip, libatlas-base-dev"
sudo apt install -y \
  python3-venv \
  python3-pip \
  libatlas-base-dev \
  libtesseract4			#required by OpenCV

#───────────────────────────────────────────────────────────────
# Step 3: Reset previous virtual environment if active
#───────────────────────────────────────────────────────────────
if [[ -n "${VIRTUAL_ENV-}" && $(type -t deactivate) == "function" ]]; then
  echo "🔄 Deactivating currently active virtual environment: $VIRTUAL_ENV"
  deactivate
fi

echo "🗑️ Removing previous venv: $ENV_NAME (if exists)"
rm -rf "$ENV_NAME"

#───────────────────────────────────────────────────────────────
# Step 4: Create and activate new virtual environment
#───────────────────────────────────────────────────────────────
echo "📦 Creating new virtual environment: $ENV_NAME"
python3 -m venv "$ENV_NAME"

echo "⚡ Activating virtual environment: $ENV_NAME"
source "$ENV_NAME/bin/activate"

#───────────────────────────────────────────────────────────────
# Step 5: Configure pip to use Jetson AI Lab package index
#───────────────────────────────────────────────────────────────
echo "🚀 Upgrading pip..."
python3 -m pip install --upgrade pip

echo "⚙️ Setting up pip configuration with Jetson AI Lab index..."
mkdir -p "$HOME/.config/pip"
cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index-url = $EXTRA_INDEX_URL
extra-index-url = https://pypi.org/simple
EOF

echo "✅ pip configuration written to: $HOME/.config/pip/pip.conf"
cat "$HOME/.config/pip/pip.conf"

#───────────────────────────────────────────────────────────────
# Step 6: Install Python dependencies
#───────────────────────────────────────────────────────────────
echo "📦 Installing Jetson-optimized Python packages (binary only)..."
#───────────────────────────────────────────────────────────────
# Optimized installation: clean cache, binary-only, Jetson index
#───────────────────────────────────────────────────────────────

echo "📦 Installing additional packages from requirements file: $REQ_FILE"
python3 -m pip install \
  --no-cache-dir \
  --force-reinstall \
  --no-index \
  -r "$REQ_FILE"
  

# Ensure a clean pip install from Jetson AI Lab index
# - no cache reuse
# - force reinstall
# - only binary wheels
# - use custom index for JetPack compatibility

rm -rf ~/.local/lib/python3.10/site-packages/tensorflow*

python3 -m pip install \
  --no-cache-dir \
  --force-reinstall \
  https://developer.download.nvidia.com/compute/redist/jp/v61/tensorflow/tensorflow-2.16.1+nv24.08-cp310-cp310-linux_aarch64.whl \
  https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/e6d/a8e91fd7e5f79/opencv_python-4.11.0-py3-none-any.whl \
  https://developer.download.nvidia.com/compute/redist/jp/v61/pytorch/torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64.whl

echo "📦 Installing ffmpeg-python"
python3 -m pip install ffmpeg-python==0.2.0

echo "🧹 Uninstalling conflicting packages (e.g., jax)..."
#python3 -m pip uninstall -y jax || true


#───────────────────────────────────────────────────────────────
# ✅ Post-install verification: TensorFlow GPU support on Jetson
#───────────────────────────────────────────────────────────────

echo "🔍 Verifying TensorFlow GPU compatibility..."

python3 - <<'EOF'
import os
import sys
import tensorflow as tf

print("📦 TensorFlow version:", tf.__version__)
print("🔧 Git version:", getattr(tf, '__git_version__', 'unknown'))

gpu_devices = tf.config.list_physical_devices('GPU')
if not gpu_devices:
    print("❌ ERROR: No GPU device detected by TensorFlow.")
    print("💡 Tip: Ensure you're using a Jetson-compatible TensorFlow wheel (e.g., 2.18.0).")
    print("🔗 Check available versions at: https://pypi.jetson-ai-lab.dev/jp6/cu126")
    sys.exit(1)
else:
    print(f"✅ GPU detected: {gpu_devices[0].name}")

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

