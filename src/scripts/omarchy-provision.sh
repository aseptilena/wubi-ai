#!/usr/bin/env bash
# =============================================================================
# Omarchy AI Workstation Automated Provisioner for Ubuntu 24.04 LTS
# Target: Native VHDX Image Deployment (Post-Install / First-Boot)
# =============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
LOGFILE="/var/log/omarchy-provision.log"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "================================================================="
echo "[+] Starting Omarchy AI Automated Provisioning: $(date)"
echo "================================================================="

# -----------------------------------------------------------------------------
# 1. Ensure Standard Ubuntu Repositories and Security Updates
# -----------------------------------------------------------------------------
echo "[*] Verifying and restoring canonical Ubuntu apt repositories..."

cat <<'EOF' > /etc/apt/sources.list
# Standard Ubuntu 24.04 LTS Repositories
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

apt-get update -y
apt-get upgrade -y

# Install standard core dependencies
apt-get install -y --no-install-recommends \
    build-essential \
    dkms \
    curl \
    wget \
    git \
    git-lfs \
    jq \
    pkg-config \
    libssl-dev \
    software-properties-common \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    htop \
    nvtop \
    tmux \
    pciutils

# -----------------------------------------------------------------------------
# 2. Hardware Acceleration & Compute Driver Setup
# -----------------------------------------------------------------------------
echo "[*] Detecting GPU architecture for hardware acceleration..."

GPU_VENDOR="none"
if lspci | grep -i nvidia > /dev/null 2>&1; then
    GPU_VENDOR="nvidia"
elif lspci | grep -i "vga.*amd\|display.*amd" > /dev/null 2>&1; then
    GPU_VENDOR="amd"
fi

echo "[+] Detected GPU Vendor: ${GPU_VENDOR}"

case "${GPU_VENDOR}" in
    "nvidia")
        echo "[*] Configuring official NVIDIA CUDA drivers..."
        ubuntu-drivers install --gpgpu || apt-get install -y nvidia-driver-550
        
        # Add NVIDIA Container Toolkit repository
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        apt-get update -y
        apt-get install -y nvidia-container-toolkit
        ;;
    "amd")
        echo "[*] Configuring AMD ROCm compute stack..."
        apt-get install -y "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"
        usermod -a -G render,video "${SUDO_USER:-ubuntu}"
        wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | tee /etc/apt/trusted.gpg.d/rocm.gpg > /dev/null
        echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ noble main" > /etc/apt/sources.list.d/rocm.list
        apt-get update -y
        apt-get install -y rocm-hip-sdk rocm-opencl-sdk
        ;;
    *)
        echo "[!] No discrete GPU detected. Falling back to AVX2/AVX-512 CPU execution paths."
        ;;
esac

# -----------------------------------------------------------------------------
# 3. Omarchy AI Workspace & Python Virtual Environment
# -----------------------------------------------------------------------------
OMARCHY_DIR="/opt/omarchy"
mkdir -p "${OMARCHY_DIR}"
echo "[*] Setting up centralized Omarchy environment in ${OMARCHY_DIR}..."

python3 -m venv "${OMARCHY_DIR}/venv"
source "${OMARCHY_DIR}/venv/bin/activate"

pip install --upgrade pip setuptools wheel

# Install PyTorch with appropriate compute backend
if [ "${GPU_VENDOR}" == "nvidia" ]; then
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
elif [ "${GPU_VENDOR}" == "amd" ]; then
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
else
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# Core AI & Inference Frameworks
pip install \
    transformers \
    accelerate \
    bitsandbytes \
    optimum \
    safetensors \
    datasets \
    peft \
    vllm \
    sentencepiece \
    fastapi \
    uvicorn \
    gradio

# -----------------------------------------------------------------------------
# 4. Fast Local Inference Engine (Ollama System Integration)
# -----------------------------------------------------------------------------
echo "[*] Deploying native Ollama runtime..."
curl -fsSL https://ollama.com/install.sh | sh

# Configure Ollama daemon for LAN/Loopback accessibility
mkdir -p /etc/systemd/system/ollama.service.d
cat <<'EOF' > /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

systemctl daemon-reload
systemctl enable --now ollama

# -----------------------------------------------------------------------------
# 5. Omarchy Unified AI Dashboard & Gateway Service
# -----------------------------------------------------------------------------
echo "[*] Creating Omarchy system management service..."

cat <<'EOF' > "${OMARCHY_DIR}/omarchy_gateway.py"
import os
import gradio as gr
import subprocess

def get_system_status():
    gpu_info = "N/A"
    try:
        gpu_info = subprocess.check_output(["nvidia-smi", "--query-gpu=name,memory.total,utilization.gpu", "--format=csv,noheader"], text=True)
    except Exception:
        gpu_info = "Running on CPU / Non-NVIDIA device"
    return f"### Omarchy AI Workstation Online\n\n**Compute Engine:**\n```\n{gpu_info}\n```"

with gr.Blocks(title="Omarchy AI Workspace") as demo:
    gr.Markdown("# 🚀 Omarchy AI Workstation (Ubuntu 24.04 VHD)")
    status = gr.Markdown(get_system_status())
    refresh = gr.Button("Refresh Status")
    refresh.click(fn=get_system_status, outputs=status)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
EOF

cat <<EOF > /etc/systemd/system/omarchy-ui.service
[Unit]
Description=Omarchy AI Workstation Gateway
After=network.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=${OMARCHY_DIR}
ExecStart=${OMARCHY_DIR}/venv/bin/python ${OMARCHY_DIR}/omarchy_gateway.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable omarchy-ui.service

# -----------------------------------------------------------------------------
# 6. Global Shell Integration & Environment Variables
# -----------------------------------------------------------------------------
cat <<'EOF' > /etc/profile.d/omarchy-env.sh
export OMARCHY_HOME="/opt/omarchy"
export PATH="/opt/omarchy/venv/bin:$PATH"
export OLLAMA_HOST="127.0.0.1:11434"
alias ai-activate="source /opt/omarchy/venv/bin/activate"
EOF
chmod +x /etc/profile.d/omarchy-env.sh

# -----------------------------------------------------------------------------
# 7. Final Cleanup
# -----------------------------------------------------------------------------
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "================================================================="
echo "[+] Omarchy AI Workstation provisioning complete."
echo "[+] Web Gateway exposed on: http://localhost:7860"
echo "[+] Ollama API exposed on:  http://localhost:11434"
echo "================================================================="
