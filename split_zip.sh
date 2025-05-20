#!/usr/bin/env bash
# ───────────────────────────────
# split_zip.sh
# Split a large zip file into 2GB chunks for GitHub Release or other services
# Usage: ./split_zip.sh my_model.zip
# ───────────────────────────────

set -euo pipefail

FILE="$1"
CHUNK_SIZE="1400m"  # 1.4GB

echo "📦 Splitting $FILE into $CHUNK_SIZE chunks..."
split -b "$CHUNK_SIZE" -d -a 2 "$FILE" "${FILE}.part"

echo "✅ Done. Generated:"
ls -lh "${FILE}.part"*

