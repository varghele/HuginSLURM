# HuginSLURM
Scripts for the graph learning workstation: HUGIN. \
First, install SLURM on the cluster and mount all drives.

## To complete SLURM setup do:
Copy the scripts into `bin` and `sbin`, then make them executable:
```bash
sudo chmod +x /usr/local/bin/check-hdd-health.sh
sudo chmod +x /usr/local/bin/slurm-safe-reboot.sh
sudo chmod +x /usr/local/bin/slurm-reboot-warning.sh
sudo chmod +x /usr/local/sbin/setup-cluster-directories.sh
sudo chmod +x /usr/local/sbin/setup-environment-modules.sh
sudo chmod +x /usr/local/sbin/setup-cuda-modules.sh
sudo chmod +x /usr/local/sbin/setup-anaconda-module.sh
sudo chmod +x /usr/local/sbin/fix-module-loading.sh
sudo chmod +x /usr/local/sbin/create-shared-docs.sh
sudo chmod +x sudo chmod +x /usr/local/sbin/generate-user-readme.sh
```
`slurm-safe-reboot.sh` and `slurm-reboot-warning.sh` go into the cron tab as preferred.
### Semi-automated setup:
To complete the setup run:
```bash
# 1. Create directory structure
sudo /usr/local/sbin/setup-cluster-directories.sh
# 2. Install environment modules
sudo /usr/local/sbin/setup-environment-modules.sh
# 3. Install CUDA versions
sudo /usr/local/sbin/setup-cuda-modules.sh
# 4. Install Anaconda
sudo /usr/local/sbin/setup-anaconda-module.sh
# 5. Add module sourcing to global bash shell (/etc/profile.d/modules.sh)
sudo /usr/local/sbin/fix-module-loading.sh
# 6. Create shared documentation
sudo /usr/local/sbin/create-shared-docs.sh
```