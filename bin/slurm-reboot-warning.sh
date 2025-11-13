#!/bin/bash
# Warn users 1 hour before reboot

# Send wall message to all logged-in users
wall "SLURM cluster will reboot in 1 hour (6 AM Monday). Please finish your jobs or they will be interrupted."

# Update node reason
scontrol update nodename=localhost reason="Reboot in 1 hour (6 AM Monday)"

# Log the warning
echo "$(date): Reboot warning sent to users" >> /var/log/slurm-reboot.log