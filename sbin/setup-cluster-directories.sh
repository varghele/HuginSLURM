#!/bin/bash
# File: /usr/local/sbin/setup-cluster-directories.sh
# Purpose: Create standard HPC directory structure

echo "========================================="
echo "Creating Cluster Directory Structure"
echo "========================================="

# Admin script directories
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/sbin
sudo mkdir -p /usr/local/share/cluster-admin/{docs,templates,scripts}

# Software installation directories
sudo mkdir -p /opt/cuda
sudo mkdir -p /opt/anaconda
sudo mkdir -p /opt/modulefiles/{cuda,anaconda,python,apps}

# Shared user resources
sudo mkdir -p /opt/shared/{datasets,models,scripts,docs}
sudo chmod 755 /opt/shared
sudo chmod 1777 /opt/shared/datasets  # Sticky bit - users can only delete their own files

# Log directories
sudo mkdir -p /var/log/cluster-admin

# Set permissions
sudo chmod 755 /usr/local/sbin
sudo chmod 755 /opt/modulefiles
sudo chmod 755 /opt/cuda
sudo chmod 755 /opt/anaconda

echo ""
echo "✓ Directory structure created!"
echo ""
echo "Directory Layout:"
echo "=================="
echo ""
echo "/usr/local/bin/              - User-facing admin scripts"
echo "  ├── add-slurm-user.sh"
echo "  ├── remove-slurm-user.sh"
echo "  ├── check-hdd-health.sh"
echo "  └── slurm-safe-reboot.sh"
echo ""
echo "/usr/local/sbin/             - System setup scripts (root only)"
echo "  ├── setup-cluster-directories.sh"
echo "  ├── setup-cuda-modules.sh"
echo "  ├── setup-anaconda-module.sh"
echo "  └── setup-environment-modules.sh"
echo ""
echo "/opt/cuda/                   - CUDA installations"
echo "  ├── 11.8/"
echo "  ├── 12.1/"
echo "  └── 12.4/"
echo "  └── .../"
echo ""
echo "/opt/anaconda/               - Anaconda installations"
echo "  └── 2025.06/"
echo ""
echo "/opt/modulefiles/            - Environment module files"
echo "  ├── cuda/"
echo "  │   ├── 11.8"
echo "  │   ├── 12.1"
echo "  │   └── 12.4"
echo "  │   └── ..."
echo "  └── anaconda/"
echo "      └── 2025.06"
echo ""
echo "/opt/shared/                 - Shared resources"
echo "  ├── datasets/              - Shared datasets"
echo "  ├── models/                - Shared models"
echo "  ├── scripts/               - Example scripts"
echo "  └── docs/                  - Documentation"
echo ""
echo "/usr/local/share/cluster-admin/ - Admin documentation"
echo "  ├── docs/                  - Guides and manuals"
echo "  ├── templates/             - Job script templates"
echo "  └── scripts/               - Helper scripts"
echo ""