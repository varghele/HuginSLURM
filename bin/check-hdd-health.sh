#!/bin/bash
# HDD health check

LOG_FILE="/var/log/hdd-health.log"

echo "=== HDD Health Check $(date) ===" >> "$LOG_FILE"
smartctl -H /dev/sda >> "$LOG_FILE"
smartctl -A /dev/sda | grep -E "Reallocated|Pending|Uncorrectable|Temperature" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Alert if drive fails
if ! smartctl -H /dev/sda | grep -q "PASSED"; then
    echo "WARNING: HDD health check FAILED!" | wall
fi