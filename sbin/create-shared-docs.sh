#!/bin/bash
# File: /usr/local/sbin/create-shared-docs.sh
# Purpose: Create shared cluster documentation

echo "Creating shared documentation..."

# Create main cluster guide
sudo tee /opt/shared/docs/CLUSTER_GUIDE.md > /dev/null <<'EOF'
# SLURM Cluster User Guide

## Quick Start

1. Log in to the cluster
2. Read your personal README: `cat ~/README.txt`
3. Set up your environment: `./setup_environment.sh`
4. Submit a test job: `sbatch ~/example_job.sh`

## Available Software

### CUDA Versions
- CUDA 11.8
- CUDA 12.1
- CUDA 12.4 (default)
- CUDA 12.6
- CUDA 12.8
- CUDA 12.9

Load with: `module load cuda/12.1`

### Python/Anaconda
- Anaconda 2025.06

Load with: `module load anaconda`

## Storage

- Home: 200GB SSD (fast, for code)
- HDD: 2TB (large, for data)

## Partitions

- **standard**: Default, 8 CPUs, 48h limit
- **quickdirty**: Testing, 8 CPUs, 1h limit
- **priorityLLM**: Priority, 8 CPUs, unlimited

## Example Job Script

```bash
#!/bin/bash
#SBATCH --job-name=training
#SBATCH --partition=standard
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00

# Load modules
module load cuda/12.1
module load anaconda

# Activate environment
conda activate myenv

# Run code
python train.py
```

## Support

Email: markus.fischer@medizin.uni-leipzig.de
EOF
# Create example job scripts
sudo mkdir -p /opt/shared/scripts

sudo tee /opt/shared/scripts/basic_gpu_job.sh > /dev/null <<'EOF'
#!/bin/bash
#SBATCH --job-name=gpu_test
#SBATCH --partition=quickdirty
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:10:00
#SBATCH --output=gpu_test_%j.out

# Load CUDA
module load cuda/12.4

# Test GPU
nvidia-smi
nvcc --version

echo "GPU test completed successfully!"
EOF

sudo tee /opt/shared/scripts/pytorch_training.sh > /dev/null <<'EOF'
#!/bin/bash
#SBATCH --job-name=pytorch_train
#SBATCH --partition=standard
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=training_%j.out
#SBATCH --error=training_%j.err

# Load modules
module load cuda/12.1
module load anaconda

# Activate your environment
conda activate pytorch

# Run training
python train.py --epochs 100 --batch-size 32

echo "Training completed at $(date)"
EOF

sudo chmod +x /opt/shared/scripts/*.sh

echo "Shared documentation created!"
echo ""
echo "Documentation available at:"
echo "  /opt/shared/docs/CLUSTER_GUIDE.md"
echo ""
echo "Example scripts available at:"
echo "  /opt/shared/scripts/"
