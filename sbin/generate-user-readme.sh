#!/bin/bash
# File: /usr/local/sbin/generate-user-readme.sh
# Purpose: Generate README template for new users

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

cat > /tmp/README_${USERNAME}.txt << EOF
========================================
SLURM CLUSTER - QUICK START GUIDE
========================================

USERNAME: ${USERNAME}

STORAGE LOCATIONS
=================

Home Directory (SSD):
  Path:  /home/${USERNAME}
  Quota: 200GB
  Use:   Code, scripts, conda environments, active projects

HDD Storage:
  Path:  /mnt/hdd/users/${USERNAME}
  Link:  ~/hdd-storage
  Quota: 2TB
  Use:   Large datasets, model checkpoints, results, archives

Check disk usage:
  quota -vs

ENVIRONMENT MODULES
===================

View available software:
  module avail

Load CUDA:
  module load cuda/12.1

Load Anaconda:
  module load anaconda

Check loaded modules:
  module list

Unload a module:
  module unload cuda

GETTING STARTED
===============

1. Set up your first conda environment:
   ./setup_environment.sh

2. Review example job script:
   cat ~/example_job.sh

3. Submit a test job:
   sbatch ~/example_job.sh

4. Check job status:
   squeue -u ${USERNAME}

SLURM PARTITIONS
================

standard    - Default partition
              8 CPUs max per job
              48 hour time limit
              Use: Regular training jobs

quickdirty  - Quick testing
              8 CPUs max per job
              1 hour time limit
              High priority
              Use: Testing and debugging

priorityLLM - Priority jobs
              8 CPUs max per job
              Unlimited time
              Use: Long-running LLM jobs

ESSENTIAL COMMANDS
==================

Job Management:
  sbatch job.sh          Submit a job
  squeue                 View all jobs
  squeue -u ${USERNAME}  View your jobs
  scancel <jobid>        Cancel a job
  scontrol show job <id> Job details

Cluster Info:
  sinfo                  Cluster status
  scontrol show node     Node details

Interactive Session:
  srun --partition=quickdirty --gres=gpu:1 --pty bash

EXAMPLE JOB SCRIPT
==================

#!/bin/bash
#SBATCH --job-name=my_training
#SBATCH --partition=standard
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=output_%j.txt
#SBATCH --error=error_%j.txt

# Load required modules
module load cuda/12.1
module load anaconda

# Activate your environment
conda activate myenv

# Run your code
python train.py

CONDA ENVIRONMENTS
==================

Create environment:
  module load anaconda
  conda create -n myproject python=3.10

Activate environment:
  conda activate myproject

Install packages:
  conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia

List environments:
  conda env list

Remove environment:
  conda env remove -n myproject

BEST PRACTICES
==============

1. Storage Strategy:
   - Keep code and environments in ~ (fast SSD)
   - Store large datasets in ~/hdd-storage (large HDD)
   - Clean up old results regularly

2. Job Submission:
   - Test in 'quickdirty' partition first
   - Always specify resource requirements
   - Use meaningful job names

3. Module Loading:
   - Always load modules in job scripts
   - Load CUDA before running GPU code
   - Check module versions: module list

4. Environment Management:
   - Create separate environments for different projects
   - Document package versions
   - Use environment.yml files

USEFUL ALIASES
==============

Add these to your ~/.bashrc:

  alias sq='squeue -u \$USER'
  alias si='sinfo'
  alias mods='module list'
  alias load-cuda='module load cuda/12.1'
  alias load-conda='module load anaconda'

TROUBLESHOOTING
===============

Job won't start:
  - Check partition limits: scontrol show partition
  - Verify resources available: sinfo
  - Check job details: scontrol show job <jobid>

CUDA not found:
  - Load CUDA module: module load cuda/12.1
  - Verify: nvcc --version

Conda not found:
  - Load Anaconda module: module load anaconda
  - Verify: conda --version

Out of disk space:
  - Check usage: quota -vs
  - Clean conda cache: conda clean --all
  - Move data to ~/hdd-storage

SHARED RESOURCES
================

Shared datasets:  /opt/shared/datasets
Shared models:    /opt/shared/models
Example scripts:  /opt/shared/scripts
Documentation:    /opt/shared/docs

SUPPORT
=======

Administrator: markus.fischer@medizin.uni-leipzig.de
Documentation: /opt/shared/docs/
Cluster Wiki:  [Add your wiki URL]

Weekly Maintenance:
  Every Monday at 6:00 AM
  Jobs will be drained before reboot

========================================
Last updated: $(date +%Y-%m-%d)
========================================
EOF

echo "/tmp/README_${USERNAME}.txt"