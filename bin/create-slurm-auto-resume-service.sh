#!/bin/bash
# File: /usr/local/sbin/create-slurm-auto-resume-service.sh
# Purpose: Create permanent systemd service to resume nodes after reboot

echo "Creating permanent SLURM auto-resume service..."

sudo tee /etc/systemd/system/slurm-auto-resume.service > /dev/null <<'EOF'
[Unit]
Description=Auto-resume SLURM nodes after reboot
After=slurmctld.service slurmd.service
Requires=slurmctld.service slurmd.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 15
ExecStart=/bin/bash -c '/usr/bin/scontrol update nodename=ALL state=resume'
ExecStartPost=/bin/bash -c 'echo "$(date): Nodes auto-resumed after reboot" >> /var/log/cluster-admin/slurm-auto-resume.log'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable slurm-auto-resume.service

echo "✓ Service created and enabled"
echo ""
echo "This service will automatically resume SLURM nodes after every reboot."
echo "Log file: /var/log/cluster-admin/slurm-auto-resume.log"
