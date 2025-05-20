# DeepFaceLab (ARM64 – Jetson AGX Orin Compatible, Ubuntu 22.04)

Jetson-compatible Linux port of **DeepFaceLab** for ARM64 devices such as the **NVIDIA Jetson AGX Orin**.

## Overview

This project brings together two discontinued forks:
- https://github.com/iperov/DeepFaceLab.git
- https://github.com/nagadit/DeepFaceLab_Linux.git; backuped - https://gitee.com/zhanghongwei_cmiot/DeepFaceLab_Linux.git

It is tailored for Jetson AGX Orin (or similar devices) with proper support for CUDA/cuDNN using Python virtual environments (`venv`).

---

## Prerequisites

Ensure basic dependencies are installed:

```bash
sudo apt update
sudo apt install -y git ffmpeg python3-venv
````

Then add NVIDIA repositories if needed:

```bash
sudo apt update
sudo apt install -y nvidia-jetpack
```

---

# Automatic Setup

```bash
chmod +x setup_env.sh
./setup_env.sh
```

---

# Manual Setup

## Setup Python Virtual Environment (Recommended)

Create and activate a clean virtual environment:

```bash
python3 -m venv ~/venvs/dfl-arm
source ~/venvs/dfl-arm/bin/activate
```

Upgrade `pip` and install the Jetson AI Lab index as a persistent source:

```bash
pip install --upgrade pip

mkdir -p ~/.config/pip
cat > ~/.config/pip/pip.conf <<EOF
[global]
extra-index-url = https://pypi.jetson-ai-lab.dev/jp6/cu126
EOF
```

> 📌 This ensures you can access optimized wheels for JetPack 6.x and CUDA 12.x.

---

## Clone the Repository and Install Dependencies

Clone this Jetson-compatible fork of DeepFaceLab:

```bash
git clone https://github.com/lamplis/DFLplus.git
cd DFLplus
```

Install Python dependencies:

```bash
pip install -r requirements-jetson.txt
```

> ⚠️ You may need to adapt versions of TensorFlow, OpenCV, or other packages to ensure compatibility with Jetson.

---

## Optional: Enable Swap if RAM is Limited

Although Jetson AGX Orin offers 64GB of RAM, devices with less memory may benefit from swap:

```bash
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```
---



## Visual Tutorial

A detailed visual guide (in Chinese) is available here:
[https://www.deepfakescn.com/?p=1202](https://www.deepfakescn.com/?p=1202)

---

## Notes for Jetson Users

* ✅ Use TensorFlow builds compatible with JetPack (see Jetson AI Lab or Nvidia-provided wheels)
* ✅ Ensure GPU acceleration is available (`tegrastats` or `nvidia-smi`)
* ✅ Tools like [JetsonHacks](https://github.com/jetsonhacks) can simplify Jetson setup

Voici un exemple de fichier `requirements-jetson.txt` **optimisé pour JetPack 6.2** (Ubuntu 22.04, Python 3.10, CUDA 12.6), compatible avec un environnement `venv` et les wheels de [Jetson AI Lab](https://pypi.jetson-ai-lab.dev).

## 📌 Remarques importantes :

1. **TensorFlow** :
   Ce fichier utilise la version Jetson-optimisée `2.12.0+nv23.06`. Assure-toi qu'elle est bien disponible via `pip install` grâce au `extra-index-url` (cf. `pip.conf`).

2. **OpenCV** :
   La version `opencv-python` ci-dessus fonctionne bien sur Jetson avec `ffmpeg` installé, mais peut être remplacée par `opencv-python-headless` si GUI inutile.

3. **Dlib** :
   Précompilé pour ARM64, mais nécessite parfois `cmake` + `boost` + `libopenblas-dev`. En cas d’erreur, utilise une roue précompilée.

4. **Mediapipe** :
   Jetson supporte `mediapipe` via les builds ARM mais attention à l’occupation GPU.

---

Souhaites-tu également un script `setup_env.sh` automatisant la création du venv, l'installation de pip.conf et le lancement de l’installation ?

