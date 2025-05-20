#!/usr/bin/env bash
source env.sh

echo "🔻️Downloading..."
wget -O /tmp/pretrain_CelebA.zip https://github.com/lamplis/jetson-deepfacelab-linux-arm64/releases/download/v1.0/pretrain_CelebA.zip

echo "📦️Unziping..."
unzip -oq /tmp/pretrain_CelebA.zip -d /tmp/pretrain_CelebA && \
    rm -rf "$DFL_ROOT/_internal/pretrain_faces" && \
    mv /tmp/pretrain_CelebA/img_align_celeba/img_align_celeba "$DFL_ROOT/_internal/pretrain_faces"

echo "🧹️Cleaning tmp files"
rm /tmp/pretrain_CelebA.zip && rm -rf /tmp/pretrain_CelebA

echo "🏆️pretrain_CelebA.zip Sucessfuly downloaded in $DFL_ROOT/_internal/pretrain_faces"
