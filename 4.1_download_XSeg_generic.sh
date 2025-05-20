#!/usr/bin/env bash
source env.sh

echo "📥Downloading..."
wget -O /tmp/model_generic_xseg.zip https://github.com/lamplis/jetson-deepfacelab-linux-arm64/releases/download/v1.0/Xseg14m.zip

echo "📂Unziping..."
rm "$DFL_ROOT/_internal/model_generic_xseg" && \
	unzip -oq /tmp/model_generic_xseg.zip -d "$DFL_ROOT/_internal/model_generic_xseg"

echo "🧹️Cleaning tmp files"
rm /tmp/model_generic_xseg.zip

echo "✅model_generic_xseg.zip Sucessfuly downloaded in $DFL_ROOT/_internal/model_generic_xseg"
