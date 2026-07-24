#!/bin/bash
# Charlotte AI Stack - Model Download Script
# Downloads all MLX models for the Charlotte AI system via LM Studio
# Run: bash download-models.sh

set -e

echo "=== Charlotte AI Stack - Model Downloader ==="
echo ""

if ! command -v lms &> /dev/null; then
    echo "Error: lms CLI not found. Install LM Studio first."
    echo "Download: https://lmstudio.ai"
    exit 1
fi

echo "Downloading models for Charlotte AI stack..."
echo ""

# 1. Coding Model - Qwen3-Coder-30B-A3B (MLX 4-bit, ~17GB)
echo "[1/5] Downloading Charlotte Coding (Qwen3-Coder-30B-A3B)..."
if lms ls 2>/dev/null | grep -q "qwen3-coder"; then
    echo "  Already installed, skipping."
else
    lms get "https://huggingface.co/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit" --mlx -y
    echo "  Done."
fi
echo ""

# 2. Reasoning Model - Qwen3.6-35B-A3B (MLX 4-bit, ~20GB)
echo "[2/5] Downloading Charlotte Reasoning (Qwen3.6-35B-A3B)..."
if lms ls 2>/dev/null | grep -q "qwen3.6-35b"; then
    echo "  Already installed, skipping."
else
    lms get "qwen/qwen3.6-35b-a3b" --mlx -y
    echo "  Done."
fi
echo ""

# 3. General Model - Gemma 4 26B-A4B (MLX 4-bit, ~16GB)
echo "[3/5] Downloading Charlotte General (Gemma 4 26B-A4B)..."
if lms ls 2>/dev/null | grep -q "gemma-4-26b"; then
    echo "  Already installed, skipping."
else
    lms get "https://huggingface.co/lmstudio-community/gemma-4-26B-A4B-it-MLX-4bit" --mlx -y
    echo "  Done."
fi
echo ""

# 4. OCR / Vision Model - Qwen3-VL-4B (MLX 4-bit, ~3GB)
echo "[4/5] Downloading OCR Specialist (Qwen3-VL-4B)..."
if lms ls 2>/dev/null | grep -q "qwen3-vl"; then
    echo "  Already installed, skipping."
else
    lms get "https://huggingface.co/lmstudio-community/Qwen3-VL-4B-Instruct-MLX-4bit" --mlx -y
    echo "  Done."
fi
echo ""

# 5. Worker Model - Qwen3-1.7B (MLX, ~2GB)
echo "[5/5] Downloading Worker (Qwen3-1.7B)..."
if lms ls 2>/dev/null | grep -q "qwen3-1.7b"; then
    echo "  Already installed, skipping."
else
    lms get "qwen/qwen3-1.7b" --mlx -y
    echo "  Done."
fi
echo ""

echo "=== Download Complete ==="
echo ""
echo "Models installed:"
lms ls
echo ""
echo "Next steps:"
echo "1. Start LM Studio server: lms server start"
echo "2. Open WebUI connects to http://localhost:1234"
