#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────
# setup_env.sh
#
# Create and activate Python venv for DeepFaceLab on Jetson
# Configure pip to use Jetson AI Lab extra index
# Install required packages
#───────────────────────────────────────────────────────────────

set -euo pipefail

ENV_NAME="dfl-arm"
PYTHON_VERSION="3.10"
REQ_FILE="requirements-jetson.txt"
EXTRA_INDEX_URL="https://pypi.jetson-ai-lab.dev/jp6/cu126"

#────────────── Install system requirements
echo "deb https://repo.download.nvidia.com/jetson/ffmpeg main main" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://repo.download.nvidia.com/jetson/ffmpeg main main" | sudo tee -a /etc/apt/sources.list

sudo apt update
sudo apt install -y python3-venv python3-pip
sudo apt-get update
sudo apt-get install libatlas-base-dev



# Assuming you're in your project root and your venv is called "$ENV_NAME"
deactivate  # if you're currently inside the venv
rm -rf "$ENV_NAME"

#────────────── Create venv
echo "📦 Creating venv: $ENV_NAME"
python3 -m venv "$ENV_NAME"

#────────────── Activate venv
source "$ENV_NAME/bin/activate"

#────────────── Upgrade pip + install pip.conf
echo "🚀 Upgrading pip and configuring extra index"
python3 -m pip install --upgrade pip

mkdir -p "$HOME/.config/pip"
cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index-url = $EXTRA_INDEX_URL
extra-index-url = https://pypi.org/simple
EOF

#────────────── Confirm pip config
echo "✅ pip will now use: $EXTRA_INDEX_URL"
cat "$HOME/.config/pip/pip.conf"

#────────────── Install requirements
echo "📦 Installing Python dependencies"
python3 -m pip install -r "$REQ_FILE"

python3 -m pip install ffmpeg-python==0.2.0

python3 -m pip uninstall jax
python3 -m pip install --force-reinstall \
	numpy mediapipe cupy tensorflow opencv-python \
	-i https://pypi.jetson-ai-lab.dev/jp6/cu126/simple/

echo "✅ Environment setup complete."
echo "💡 Activate with: source $ENV_NAME/bin/activate"

