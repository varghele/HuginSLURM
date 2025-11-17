#!/bin/bash

echo "=========================================="
echo "Munin LLM Service Monitor"
echo "=========================================="
echo ""

# Check SLURM job
echo "SLURM Job Status:"
squeue -u llm-service -o "%.10i %.12P %.20j %.8u %.2t %.10M %.10L %.6D %R"
echo ""

# Check Docker container
echo "Docker Container:"
sudo docker ps --filter "name=llm-webui" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
echo ""

# Check if service file exists
if [ -f /opt/llm-service/current_node.txt ]; then
    echo "Service Status: ✅ ACTIVE"
    echo ""

    # Check vLLM health
    echo "vLLM Health Check:"
    HEALTH=$(curl -s http://localhost:8000/health)
    if [ $? -eq 0 ]; then
        echo "✓ vLLM responding"
    else
        echo "✗ vLLM not responding"
    fi
    echo ""

    # Check Open WebUI
    echo "Open WebUI Check:"
    WEBUI=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
    if [ "$WEBUI" = "200" ]; then
        echo "✓ Open WebUI responding"
    else
        echo "✗ Open WebUI not responding (HTTP $WEBUI)"
    fi
else
    echo "Service Status: ❌ INACTIVE"
fi

echo ""

# GPU usage
echo "GPU Usage:"
nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | \
    awk -F', ' '{printf "GPU %s (%s): %s%% utilization, %sMB / %sMB memory, %s°C\n", $1, $2, $3, $4, $5, $6}'
echo ""

# Memory usage
echo "System Memory:"
free -h | grep Mem | awk '{printf "Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
echo ""

# Recent logs
echo "Recent Log Entries (last 5 lines):"
tail -n 5 /opt/llm-service/logs/service-*.out 2>/dev/null || echo "No logs available"