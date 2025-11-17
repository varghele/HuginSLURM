#!/bin/bash
# /usr/local/bin/slurm-safe-reboot.sh
# Safe SLURM reboot script - nodes will auto-resume via systemd service

LOG_FILE="/var/log/cluster-admin/slurm-reboot.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p /var/log/cluster-admin

echo "=========================================" | tee -a "$LOG_FILE"
echo "$TIMESTAMP: Starting safe SLURM reboot" | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Must run as root (use sudo)" | tee -a "$LOG_FILE"
    exit 1
fi

# Get list of all nodes
NODES=$(scontrol show nodes | grep NodeName | awk '{print $1}' | cut -d= -f2 | tr '\n' ',' | sed 's/,$//')
if [ -z "$NODES" ]; then
    NODES="localhost"
fi

echo "Nodes to drain: $NODES" | tee -a "$LOG_FILE"

# 1. Set nodes to DRAIN state - prevents new jobs from starting
echo "Setting nodes to DRAIN..." | tee -a "$LOG_FILE"
scontrol update nodename=$NODES state=drain reason="Weekly Monday reboot - $(date)"

# 2. Check for running jobs
RUNNING_JOBS=$(squeue -h -t R | wc -l)
echo "Currently running jobs: $RUNNING_JOBS" | tee -a "$LOG_FILE"

if [ $RUNNING_JOBS -gt 0 ]; then
    echo "Waiting for running jobs to complete..." | tee -a "$LOG_FILE"

    # Wait for all jobs to finish (check every 30 seconds, max 2 hours)
    timeout=7200  # 2 hours in seconds
    elapsed=0

    while [ $(squeue -h -t R | wc -l) -gt 0 ] && [ $elapsed -lt $timeout ]; do
        running_jobs=$(squeue -h -t R | wc -l)
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $running_jobs jobs still running..." | tee -a "$LOG_FILE"
        sleep 30
        elapsed=$((elapsed + 30))
    done

    # Check if timeout was reached
    if [ $(squeue -h -t R | wc -l) -gt 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - Timeout reached. Force rebooting with running jobs." | tee -a "$LOG_FILE"
        squeue -t R | tee -a "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S'): All jobs completed successfully" | tee -a "$LOG_FILE"
    fi
else
    echo "No running jobs. Proceeding with reboot." | tee -a "$LOG_FILE"
fi

# 3. Stop SLURM services gracefully
echo "$(date '+%Y-%m-%d %H:%M:%S'): Stopping SLURM services..." | tee -a "$LOG_FILE"
systemctl stop slurmctld
systemctl stop slurmd

# 4. Note about auto-resume
echo "$(date '+%Y-%m-%d %H:%M:%S'): Nodes will be auto-resumed by slurm-auto-resume.service after reboot" | tee -a "$LOG_FILE"

# 5. Reboot the system
echo "$(date '+%Y-%m-%d %H:%M:%S'): Initiating system reboot..." | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"

# Reboot
/sbin/reboot
