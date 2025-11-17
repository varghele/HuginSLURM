#!/bin/bash

# Only run on weekdays (Monday-Friday)
DAY=$(date +%u)
if [ $DAY -ge 6 ]; then
    echo "$(date): Weekend - service not scheduled" >> /opt/llm-service/logs/scheduler.log
    exit 0
fi

# Check if service is already running
RUNNING=$(squeue -u llm-service -n llm-service -h -o %i)
if [ -n "$RUNNING" ]; then
    echo "$(date): Service already running (Job ID: $RUNNING)" >> /opt/llm-service/logs/scheduler.log
    exit 0
fi

# Submit job as llm-service user
echo "$(date): Starting service" >> /opt/llm-service/logs/scheduler.log
sudo -u llm-service sbatch /opt/llm-service/scripts/start_service.sh