#!/bin/bash
# Safe SLURM reboot script

echo "$(date): Starting safe SLURM reboot"

# Set node to DRAIN state - prevents new jobs from starting
scontrol update nodename=localhost state=drain reason="Weekly Monday reboot"

echo "Node set to DRAIN. Waiting for running jobs to complete..."

# Wait for all jobs to finish (check every 30 seconds, max 2 hours)
timeout=7200  # 2 hours in seconds
elapsed=0

while [ $(squeue -h -t R | wc -l) -gt 0 ] && [ $elapsed -lt $timeout ]; do
    running_jobs=$(squeue -h -t R | wc -l)
    echo "$(date): $running_jobs jobs still running..."
    sleep 30
    elapsed=$((elapsed + 30))
done

if [ $(squeue -h -t R | wc -l) -gt 0 ]; then
    echo "$(date): Timeout reached. Force rebooting with running jobs."
fi

echo "$(date): Rebooting..."

# Reboot the system
/sbin/reboot