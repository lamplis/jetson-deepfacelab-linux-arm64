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

`./0.sh` opens the script menu. `./0.sh 5.3.1` runs one script by its id.

Each aligned JPEG stores two separate mask fields. SAEHD training reads the raster `xseg_mask` whenever it exists, and ignores polygons until that raster is rewritten.

* `seg_ie_polys` — editable polygons (include keeps a region, exclude cuts a hole).
* `xseg_mask` — the black-and-white mask used by SAEHD. It is written by XSeg apply, by key `8`, or by `5.3.5_XSeg_data_src_polys_to_mask.sh` and `5.3.6_XSeg_data_dst_polys_to_mask.sh`.

Open the editor with `5.3.1_XSeg_data_src_mask_edit.sh` or `5.3.2_XSeg_data_dst_mask_edit.sh`.

| Key | Action |
| --- | --- |
| `Q` / `W` | New polygon is include / exclude |
| `1` `2` `3` | Show the photo and the polygons |
| `4` | Mask baked from the polygons only |
| `5` | Applied raster mask (no points) |
| `` ` `` | Applied mask shaded over the photo |
| `6` | Turn the applied mask into polygons that follow the mask edge. The outer contour is an include. When the face has 68 landmarks, the open-mouth hole is not turned into an exclude. Other holes stay excludes. |
| `7` | Replace polygons with one include from the 68 landmarks. The jaw follows the landmarks. The top is extended past the eyebrows to about the hairline, because those 68 points stop at the brows. The mouth interior is inside it. Inactive when the face has no 68-point landmarks. |
| `8` | Rewrite `xseg_mask` from the current image's polygons. The folder scripts bake every face. |
| `A` / `D` | Save and go to the previous / next image |

`6` and `7` replace the polygons of the current image only. They do not run when you change image. `6` is inactive when the image has no applied mask. `8` updates the raster in memory; `A` or `D` writes it. Closing the window does not save.

Right-click the outline of a selected polygon, within 8 screen pixels of the stroke. On an edge, the menu adds a point. On a point, it deletes that point. Left-click still moves a point.

### Applying a mask to a whole faceset

* `4.3.4_download_XSeg_generic.sh`, then `5.4.4_XSeg_generic_wf_data_src_apply.sh` or `5.4.5_XSeg_generic_wf_data_dst_apply.sh` — pretrained whole-face XSeg.
* `5.4.1_XSeg_train.sh`, then `5.4.2_XSeg_data_src_mask_apply.sh` or `5.4.3_XSeg_data_dst_mask_apply.sh` — your own XSeg model. Training uses polygon-labeled faces when any exist.
* Face parser ([yakhyo/face-parsing](https://github.com/yakhyo/face-parsing) BiSeNet ResNet34), then a manual pass, then the mask. `onnxruntime` comes from `requirements-jetson.txt`. The published wheel runs on CPU. The weight is not part of the git tree.
  1. `4.3.5_download_face_parser.sh` once. It saves `_internal/DeepFaceLab/model_face_parser/resnet34.onnx`.
  2. `5.3.3_XSeg_data_src_face_parse.sh` or `5.3.4_XSeg_data_dst_face_parse.sh` replaces `seg_ie_polys` on every aligned face. Points are kept about every 2 pixels along the parser contour, including the forehead. Ears stay outside the polygon. The existing `xseg_mask` is left in place. Default `--inner-mouth include` keeps the oral cavity and teeth (yakhyo class `mouth`, index 11). Both lips (12 and 13) stay in the polygon either way. Pass `--inner-mouth exclude` on the `xseg parse` command to leave that cavity black while keeping the lips.
  3. Close the editor if it is open, then `5.3.1_XSeg_data_src_mask_edit.sh` or `5.3.2_XSeg_data_dst_mask_edit.sh`. Press `1`, `2`, or `3` to see and fix the points. `A` or `D` saves them. Key `5` shows the old raster and hides the points, and that view stays on for the next images in the session.
  4. Close the editor, then `5.3.5_XSeg_data_src_polys_to_mask.sh` or `5.3.6_XSeg_data_dst_polys_to_mask.sh`. That writes `xseg_mask` from the polygons and keeps the polygons, so you can edit and bake again. SAEHD reads this raster. XSeg training still reads the polygons when any face in the folder has them. Key `8` does the same bake for the current image only.

`5.5.1_XSeg_data_src_mask_remove.sh` and `5.5.2_XSeg_data_dst_mask_remove.sh` delete the polygons (`xseg remove_labels`). `5.5.3_XSeg_data_src_trained_mask_remove.sh` and `5.5.4_XSeg_data_dst_trained_mask_remove.sh` delete the applied raster (`xseg remove`). The names are easy to swap.

## Notes for Jetson Users

* TensorFlow must be compatible with JetPack (you can use Nvidia-provided wheels).
* Ensure GPU acceleration is working (test with `nvidia-smi` or `tegrastats`).
* Consider using [Jetson Hacks](https://github.com/jetsonhacks) for environment setup.
