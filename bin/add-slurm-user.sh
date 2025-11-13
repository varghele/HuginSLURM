#!/bin/bash
# add-slurm-user.sh - User creation script for SLURM cluster with module support

USERNAME=$1
PASSWORD=$2
SSD_QUOTA="200G"
HDD_QUOTA="2T"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <username> <password>"
    echo "Example: $0 alice MySecurePass123"
    exit 1
fi

echo "========================================="
echo "Creating SLURM user: $USERNAME"
echo "========================================="

# Create user account
echo "Creating user account..."
sudo useradd -m -s /bin/bash "$USERNAME"

# Set password
echo "Setting password..."
echo "$USERNAME:$PASSWORD" | sudo chpasswd

# Create HDD storage directory
echo "Creating HDD storage directory..."
sudo mkdir -p "/mnt/hdd/users/$USERNAME"
sudo chown "$USERNAME:$USERNAME" "/mnt/hdd/users/$USERNAME"
sudo chmod 700 "/mnt/hdd/users/$USERNAME"

# Create symlink in user's home
sudo ln -s "/mnt/hdd/users/$USERNAME" "/home/$USERNAME/hdd-storage"

# Set quotas with error checking
echo "Setting SSD quota..."
if sudo setquota -u "$USERNAME" 200G 210G 0 0 /; then
    echo "SSD quota set successfully"
else
    echo "  ERROR: Failed to set SSD quota"
fi

echo "Setting HDD quota..."
if sudo setquota -u "$USERNAME" 2T 2.1T 0 0 /mnt/hdd; then
    echo "HDD quota set successfully"
else
    echo "  ERROR: Failed to set HDD quota"
    echo "  Checking if quotas are enabled..."
    sudo quotaon -p /mnt/hdd
fi

# Create example job script with module support
cat > /tmp/example_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --partition=standard
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=output_%j.txt
#SBATCH --error=error_%j.txt

# Load required modules
module load cuda/12.1
module load anaconda

# Activate your conda environment
conda activate myenv

# Verify setup
echo "Job started at $(date)"
echo "Working directory: $(pwd)"
echo ""
echo "Loaded modules:"
module list
echo ""
echo "CUDA version:"
nvcc --version
echo ""
echo "Python version:"
python --version
echo ""
echo "Conda environment:"
conda info --envs

# Your code here
# python train.py

echo ""
echo "Job finished at $(date)"
EOF

sudo mv /tmp/example_job.sh "/home/$USERNAME/example_job.sh"
sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/example_job.sh"
sudo chmod +x "/home/$USERNAME/example_job.sh"

# Create environment setup script
echo "Creating environment setup script..."
cat > /tmp/setup_environment.sh << 'EOF'
#!/bin/bash
# Setup script to create your first conda environment

echo "========================================="
echo "Setting up your Python environment"
echo "========================================="
echo ""

# Load Anaconda module
echo "Loading Anaconda module..."
module load anaconda

# Create a PyTorch environment
echo "Creating PyTorch environment (this may take a few minutes)..."
conda create -n pytorch python=3.10 -y

# Activate it
echo "Activating environment..."
source ~/.bashrc
conda activate pytorch

# Install PyTorch with CUDA support
echo "Installing PyTorch with CUDA 12.1..."
conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y

# Install common packages
echo "Installing common ML packages..."
conda install numpy pandas scikit-learn matplotlib jupyter -y

echo ""
echo "========================================="
echo "Environment setup complete!"
echo "========================================="
echo ""
echo "To use this environment:"
echo "  1. Load Anaconda: module load anaconda"
echo "  2. Activate environment: conda activate pytorch"
echo ""
echo "In SLURM jobs, add these lines:"
echo "  module load cuda/12.1"
echo "  module load anaconda"
echo "  conda activate pytorch"
echo ""
echo "Test your setup:"
echo "  python -c 'import torch; print(torch.cuda.is_available())'"
echo ""
EOF

sudo mv /tmp/setup_environment.sh "/home/$USERNAME/setup_environment.sh"
sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/setup_environment.sh"
sudo chmod +x "/home/$USERNAME/setup_environment.sh"

# Generate and install README using the generator script
echo "Creating user README..."
if [ -f /usr/local/sbin/generate-user-readme.sh ]; then
    README_FILE=$(/usr/local/sbin/generate-user-readme.sh "$USERNAME")
    sudo mv "$README_FILE" "/home/$USERNAME/README.txt"
    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/README.txt"
else
    # Fallback: create basic README if generator doesn't exist
    cat > /tmp/README.txt << EOF
========================================
SLURM CLUSTER - QUICK START GUIDE
========================================

USERNAME: $USERNAME

STORAGE LOCATIONS
=================

Home (SSD): /home/$USERNAME
- Fast NVMe SSD storage
- Quota: 200GB
- Use for: Code, scripts, conda environments

HDD Storage: ~/hdd-storage
- Real path: /mnt/hdd/users/$USERNAME
- Large HDD storage (21.8TB total)
- Quota: 2TB
- Use for: Datasets, results, archives

Check usage: quota -vs

ENVIRONMENT MODULES
===================

View available modules:
  module avail

Load CUDA:
  module load cuda/12.1

Load Anaconda:
  module load anaconda

Check loaded modules:
  module list

GETTING STARTED
===============

1. Set up your first conda environment:
   ./setup_environment.sh

2. Review example job script:
   cat ~/example_job.sh

3. Submit a test job:
   sbatch ~/example_job.sh

SLURM PARTITIONS
================

standard    - Default (8 CPUs max, 48h limit)
quickdirty  - Quick tests (8 CPUs, 1h, high priority)
priorityLLM - Priority jobs (8 CPUs, unlimited)

ESSENTIAL COMMANDS
==================

Submit job:     sbatch job_script.sh
Check queue:    squeue
Your jobs:      squeue -u $USERNAME
Cancel job:     scancel <jobid>
Cluster status: sinfo

Interactive GPU:
  srun --partition=quickdirty --gres=gpu:1 --pty bash

EXAMPLE JOB
===========

See ~/example_job.sh for a complete template.

Remember to load modules in your job scripts:
  module load cuda/12.1
  module load anaconda
  conda activate myenv

========================================
EOF
    sudo mv /tmp/README.txt "/home/$USERNAME/README.txt"
    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/README.txt"
fi

# Add helpful aliases to user's .bashrc
echo "Adding helpful aliases..."
cat >> /tmp/bashrc_additions << 'EOF'

# SLURM Cluster Aliases
alias sq='squeue -u $USER'
alias si='sinfo'
alias mods='module list'
alias ma='module avail'

# Quick module loading
alias load-cuda='module load cuda/12.1'
alias load-conda='module load anaconda'

# Conda shortcuts
alias ca='conda activate'
alias cda='conda deactivate'
alias cel='conda env list'
EOF

sudo tee -a "/home/$USERNAME/.bashrc" < /tmp/bashrc_additions > /dev/null
sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.bashrc"
rm /tmp/bashrc_additions

echo ""
echo "========================================="
echo "✓ User $USERNAME created successfully!"
echo "========================================="
echo ""
echo "STORAGE:"
echo "  Home (SSD):  /home/$USERNAME"
echo "               Quota: 200GB on 3.6TB NVMe SSD"
echo ""
echo "  HDD storage: /mnt/hdd/users/$USERNAME"
echo "               Accessible via: ~/hdd-storage"
echo "               Quota: 2TB on 21.8TB HDD"
echo ""
echo "FILES CREATED:"
echo "  ~/README.txt              - Complete user guide"
echo "  ~/example_job.sh          - Example SLURM job with modules"
echo "  ~/setup_environment.sh    - Create first conda environment"
echo ""
echo "NEXT STEPS FOR USER:"
echo "  1. Log in as $USERNAME"
echo "  2. Read the guide: cat ~/README.txt"
echo "  3. Set up environment: ./setup_environment.sh"
echo "  4. Test with: sbatch ~/example_job.sh"
echo ""
echo "AVAILABLE MODULES:"
module avail 2>&1 | grep -E "cuda|anaconda" | sed 's/^/  /'
echo ""
echo "DISK USAGE:"
sudo quota -vs "$USERNAME" 2>/dev/null || echo "  (Quotas will show after first use)"
echo ""
echo "========================================="
