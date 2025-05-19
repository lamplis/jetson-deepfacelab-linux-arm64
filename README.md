# DeepFaceLab (ARM64 – Jetson AGX Orin Compatible, Ubuntu 22.04)
Jetson DeepFaceLab Linux ARM64

## Overview

This is a Linux-based version of **DeepFaceLab**, adapted for ARM64 platforms such as the **NVIDIA Jetson AGX Orin**.  
This guide helps you set up the environment using `Miniconda` instead of Anaconda3 (lighter for embedded systems) and configures the project to run on Jetson with proper CUDA/cuDNN support.
This the assembly of 2 forks of dead projects:
- https://github.com/iperov/DeepFaceLab.git
- https://gitee.com/zhanghongwei_cmiot/DeepFaceLab_Linux.git 

---

## Prerequisites

Make sure Git and FFmpeg are installed on your Jetson system:

```bash
sudo apt update
sudo apt install -y git ffmpeg
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

## Notes for Jetson Users

* TensorFlow must be compatible with JetPack (you can use Nvidia-provided wheels).
* Ensure GPU acceleration is working (test with `nvidia-smi` or `tegrastats`).
* Consider using [Jetson Hacks](https://github.com/jetsonhacks) for environment setup.
