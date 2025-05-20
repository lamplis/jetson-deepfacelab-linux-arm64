#!/usr/bin/env bash
source env.sh

set -euo pipefail

# Define base URL and filenames
BASE_URL="https://github.com/lamplis/jetson-deepfacelab-linux-arm64/releases/download/v1.0"
OUTPUT_DIR="$DFL_WORKSPACE"
MERGED_ZIP="$OUTPUT_DIR/model/saehd_liae_model.zip"

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "📥 Downloading ZIP parts..."
mkdir -p /tmp/saehd_liae_model
wget -cO /tmp/saehd_liae_model/model.zip.part00 "$BASE_URL/LIAE-UDT_WF_352_352_80_80_24_AB_1M_MrDrMasterChef.zip.part00"
wget -cO /tmp/saehd_liae_model/model.zip.part01 "$BASE_URL/LIAE-UDT_WF_352_352_80_80_24_AB_1M_MrDrMasterChef.zip.part01"

echo "🧩 Merging parts into $MERGED_ZIP"
cat /tmp/saehd_liae_model/model.zip.part* > "$MERGED_ZIP"

echo "📂 Extracting archive..."
	unzip -oq "$MERGED_ZIP" -d "$OUTPUT_DIR"

echo "✅ Extraction complete: Files available in $OUTPUT_DIR"

echo "🧹️Cleaning tmp files"
rm -rf /tmp/saehd_liae_model
