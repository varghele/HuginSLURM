#!/bin/bash
#SBATCH --job-name=llm-service
#SBATCH --partition=priorityLLM
#SBATCH --gres=gpu:rtx5090:1
#SBATCH --time=14:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=/opt/llm-service/logs/service-%j.out
#SBATCH --error=/opt/llm-service/logs/service-%j.err

# Service configuration
COMPUTE_NODE=$(hostname)
MODEL_PATH="/opt/llm-service/models/llama-3.1-70b-awq"
VLLM_PORT=8000
WEBUI_PORT=8080
DATA_DIR="/opt/llm-service/data"

echo "=========================================="
echo "LLM Service Starting"
echo "=========================================="
echo "Node: $COMPUTE_NODE"
echo "Job ID: $SLURM_JOB_ID"
echo "Start Time: $(date)"
echo "Model: Llama 3.1 8B AWQ INT4"
echo "GPU: 1x RTX 5090"
echo "CPUs: 8 cores"
echo "RAM: 64GB"
echo "=========================================="

# Activate environment
source /opt/llm-service/vllm-env/bin/activate

# Start vLLM server on SINGLE GPU
echo "Starting vLLM server on single GPU..."
vllm serve $MODEL_PATH \
    --host 127.0.0.1 \
    --port $VLLM_PORT \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.75 \
    --max-model-len 4098 \
    --quantization awq \
    --disable-log-requests \
    --trust-remote-code \
    --max-num-seqs 4 \
    --enforce-eager&

VLLM_PID=$!
echo "vLLM PID: $VLLM_PID"

# Wait for vLLM to be ready
echo "Waiting for vLLM to initialize (this may take 2-3 minutes)..."
for i in {1..180}; do
    if curl -s http://127.0.0.1:$VLLM_PORT/health > /dev/null 2>&1; then
        echo "✓ vLLM is ready!"
        break
    fi
    if [ $i -eq 180 ]; then
        echo "✗ vLLM failed to start within timeout"
        exit 1
    fi
    sleep 2
done

# Start Open WebUI
echo "Starting Open WebUI..."
docker run -d \
    --name llm-webui-$SLURM_JOB_ID \
    --network host \
    -e OPENAI_API_BASE_URLS="http://127.0.0.1:$VLLM_PORT/v1" \
    -e OPENAI_API_KEYS="dummy" \
    -e WEBUI_AUTH="True" \
    -e WEBUI_NAME="Munin Research AI Assistant" \
    -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
    -e ENABLE_SIGNUP="True" \
    -e DEFAULT_USER_ROLE="user" \
    -e DEFAULT_MODELS="llama-3.1-8b-awq" \
    -v $DATA_DIR:/app/backend/data \
    ghcr.io/open-webui/open-webui:main

WEBUI_CONTAINER="llm-webui-$SLURM_JOB_ID"

# Wait for Open WebUI
echo "Waiting for Open WebUI to initialize..."
sleep 30

# Verify services
if docker ps | grep -q $WEBUI_CONTAINER; then
    echo "✓ Open WebUI is running!"
else
    echo "✗ Open WebUI failed to start"
    docker logs $WEBUI_CONTAINER
    kill $VLLM_PID
    exit 1
fi

echo "=========================================="
echo "✅ Service is LIVE!"
echo "=========================================="
echo "Access URL: http://$COMPUTE_NODE:$WEBUI_PORT"
echo ""
echo "Resource Usage:"
echo "  GPU: 1x RTX 5090 (~18-20GB VRAM)"
echo "  CPUs: 8 cores"
echo "  RAM: ~40-50GB (out of 64GB allocated)"
echo ""
echo "Users connect with:"
echo "ssh -L $WEBUI_PORT:localhost:$WEBUI_PORT username@munin"
echo "Then visit: http://localhost:$WEBUI_PORT"
echo "=========================================="

# Save connection info for users
echo "localhost" > /opt/llm-service/current_node.txt
chmod 644 /opt/llm-service/current_node.txt

# Cleanup function
cleanup() {
    echo ""
    echo "Shutting down service..."
    docker stop $WEBUI_CONTAINER 2>/dev/null
    docker rm $WEBUI_CONTAINER 2>/dev/null
    kill $VLLM_PID 2>/dev/null
    rm -f /opt/llm-service/current_node.txt
    echo "✓ Shutdown complete"
}

trap cleanup EXIT SIGTERM SIGINT

# Keep job alive
wait $VLLM_PID