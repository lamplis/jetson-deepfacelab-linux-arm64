# DeepFaceLab (ARM64 – Jetson AGX Orin Compatible, Ubuntu 22.04)
Jetson DeepFaceLab Linux ARM64

## Overview

This is a Linux-based version of **DeepFaceLab**, adapted for ARM64 platforms such as the **NVIDIA Jetson AGX Orin**.  
This guide helps you set up the environment using `Miniconda` instead of Anaconda3 (lighter for embedded systems) and configures the project to run on Jetson with proper CUDA/cuDNN support.
The DeepFaceLab sources come from:
- https://github.com/lamplis/DFLplus.git
- https://gitee.com/zhanghongwei_cmiot/DeepFaceLab_Linux.git 

---

## Prerequisites

Make sure Git and FFmpeg are installed on your Jetson system:

```bash
sudo apt update
sudo apt install -y git ffmpeg fontconfig fonts-dejavu-core
````

---

## Install Miniconda (Recommended for Jetson)

Download and install Miniconda (lighter than Anaconda):

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
bash Miniconda3-latest-Linux-aarch64.sh
```

Follow the prompts (press ENTER several times and accept with `yes`).

Then initialize the environment:

```bash
export PATH=~/miniconda3/bin:$PATH
conda init bash
```

---

## Create a Conda Environment for DeepFaceLab

Create and activate a Conda environment with Jetson-compatible Python and CUDA libraries (JetPack 6.x includes CUDA 12.x):

```bash
conda create -y -n dfl-arm python=3.8
conda activate dfl-arm
```

> ⚠️ Note: The original DFL used `python=3.6` and `cudatoolkit=9.0`, but these are not compatible with Jetson CUDA 12. Use updated packages and patch the code if needed.

---

## Clone the DeepFaceLab Repository and Install Requirements

Clone the Jetson-compatible fork (or adapt the original as needed):

```bash
git clone https://github.com/lamplis/DFLplus.git
cd DFLplus
```

Install Python dependencies:

```bash
pip install --upgrade pip
pip install -r requirements-jetson.txt
```

> 🛠️ You may need to adapt the requirements if you encounter version conflicts (e.g. TensorFlow or OpenCV on Jetson).

---

## Optional: Use Swap if RAM is Low

Jetson AGX Orin has 64GB RAM, but for other devices you can enable swap:

```bash
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## Visual Tutorial

Visit the following link for a step-by-step visual guide (in Chinese):
[https://www.deepfakescn.com/?p=1202](https://www.deepfakescn.com/?p=1202)

---

## XSeg masks

Each aligned JPEG stores two separate mask fields. SAEHD training reads the raster `xseg_mask` whenever it exists, and ignores polygons until that raster is rewritten.

* `seg_ie_polys` — editable polygons (include keeps a region, exclude cuts a hole).
* `xseg_mask` — the black-and-white mask produced by XSeg apply or by the face parser.

Open the editor with `5_XSeg_data_src_mask_edit.sh` or `5_XSeg_data_dst_mask_edit.sh`.

| Key | Action |
| --- | --- |
| `Q` / `W` | New polygon is include / exclude |
| `1` `2` `3` | Show the photo and the polygons |
| `4` | Mask baked from the polygons only |
| `5` | Applied raster mask (no points) |
| `` ` `` | Applied mask shaded over the photo |
| `6` | Turn the applied mask into polygons that follow the mask edge. The outer contour is an include. When the face has 68 landmarks, the open-mouth hole is not turned into an exclude. Other holes stay excludes. |
| `7` | Replace polygons with one include from the 68 landmarks (jaw, then the eyebrow line, 27 points). The mouth interior is inside it. Inactive when the face has no 68-point landmarks. |
| `8` | Rewrite `xseg_mask` from the current polygons |
| `A` / `D` | Save and go to the previous / next image |

`6` and `7` replace the polygons of the current image only. They do not run when you change image. `6` is inactive when the image has no applied mask. `8` updates the raster in memory; `A` or `D` writes it. Closing the window does not save.

### Applying a mask to a whole faceset

* `4.1_download_XSeg_generic.sh`, then `5_XSeg_generic_wf_data_src_apply.sh` or `5_XSeg_generic_wf_data_dst_apply.sh` — pretrained whole-face XSeg.
* `5_XSeg_train.sh`, then `5_XSeg_data_src_mask_apply.sh` or `5_XSeg_data_dst_mask_apply.sh` — your own XSeg model. Training uses polygon-labeled faces when any exist.
* `4.2_download_face_parser.sh`, then `5_XSeg_data_src_face_parse.sh` or `5_XSeg_data_dst_face_parse.sh` — BiSeNet ResNet18 ([yakhyo/face-parsing](https://github.com/yakhyo/face-parsing)). The weight is downloaded to `_internal/DeepFaceLab/model_face_parser/resnet18.onnx` and is not part of the git tree. `onnxruntime` comes from `requirements-jetson.txt`. The published wheel runs on CPU. Default `--inner-mouth include` keeps the oral cavity and teeth (CelebAMask-HQ class `mouth`). Pass `--inner-mouth exclude` on the `xseg parse` command to leave that cavity black while keeping the lips. Existing polygons are left in place.

`5_XSeg_data_*_mask_remove.sh` deletes the polygons (`xseg remove_labels`). `5_XSeg_data_*_trained_mask_remove.sh` deletes the applied raster (`xseg remove`). The names are easy to swap.

## Notes for Jetson Users

* TensorFlow must be compatible with JetPack (you can use Nvidia-provided wheels).
* Ensure GPU acceleration is working (test with `nvidia-smi` or `tegrastats`).
* Consider using [Jetson Hacks](https://github.com/jetsonhacks) for environment setup.
