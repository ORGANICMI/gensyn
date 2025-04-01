#!/bin/bash

set -e

echo "🧠 Gensyn RL-Swarm 一键安装脚本 for Linux（支持 GPU / CPU 模式）"

# 获取 Ubuntu 主版本号（20 / 22 / 24）
UBUNTU_VERSION=$(lsb_release -rs | cut -d. -f1)

# 根据版本选择 Python 安装包
if [[ "$UBUNTU_VERSION" == "20" ]]; then
  PYTHON_EXEC=python3.10
  PYTHON_PKG="python3.10 python3.10-venv python3.10-dev"
elif [[ "$UBUNTU_VERSION" == "22" ]]; then
  PYTHON_EXEC=python3.10
  PYTHON_PKG="python3.10 python3.10-venv python3.10-dev"
elif [[ "$UBUNTU_VERSION" == "24" ]]; then
  PYTHON_EXEC=python3
  PYTHON_PKG="python3 python3-venv python3-dev"
else
  echo "❌ 暂不支持该 Ubuntu 版本，请使用 20.04 / 22.04 / 24.04"
  exit 1
fi

# 安装基础工具和 Python
echo "📦 安装基础依赖..."
sudo apt update
sudo apt install -y git curl wget build-essential $PYTHON_PKG

# 安装 Node.js 18 + Yarn
if ! command -v node &> /dev/null; then
  echo "🧱 安装 Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

echo "🧵 启用 corepack + Yarn..."
corepack enable
corepack prepare yarn@stable --activate

# 克隆仓库
if [ ! -d "rl-swarm" ]; then
  echo "🔁 克隆 gensyn-ai/rl-swarm 仓库..."
  git clone https://github.com/gensyn-ai/rl-swarm.git
fi
cd rl-swarm

# 创建虚拟环境
echo "🧪 创建 Python 虚拟环境..."
$PYTHON_EXEC -m venv .venv
source .venv/bin/activate

# 安装 Python 依赖
pip install --upgrade pip
pip install -r requirements.txt

# 运行模式选择
echo ""
echo "🧠 请选择运行模式："
echo "1) CPU-only（推荐，稳定不崩溃）"
echo "2) GPU（需 NVIDIA CUDA）"
read -p "请输入选项编号 [默认 1]：" mode_choice

if [[ "$mode_choice" == "2" ]]; then
  echo "🚀 使用 GPU 模式（确保你已安装 CUDA 驱动）"
else
  echo "🛡️ 启用 CPU-only 模式"
  export PYTORCH_ENABLE_MPS_FALLBACK=1
  export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
  sed -i 's/torch\.device("mps" if torch\.backends\.mps\.is_available() else "cpu")/torch.device("cpu")/g' hivemind_exp/trainer/hivemind_grpo_trainer.py
fi

# 启动节点
echo "🚀 启动 RL-Swarm 节点..."
echo "⚠️ 当提示是否加入 testnet 时，请输入 Y 或直接回车。"
sleep 2
bash run_rl_swarm.sh
