#!/bin/bash
# setup-anaconda-module.sh - Install Anaconda as an environment module

ANACONDA_VERSION="2025.06-1"
ANACONDA_INSTALLER="Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh"
INSTALL_BASE="/opt/anaconda"
INSTALL_DIR="$INSTALL_BASE/2025.06"
MODULE_DIR="/opt/modulefiles/anaconda"

echo "========================================="
echo "Installing Anaconda as Environment Module"
echo "========================================="

# Create directories
sudo mkdir -p "$INSTALL_BASE"
sudo mkdir -p "$MODULE_DIR"

# Download Anaconda
echo "Downloading Anaconda..."
cd /tmp
if [ ! -f "$ANACONDA_INSTALLER" ]; then
    wget -q --show-progress \
        https://repo.anaconda.com/archive/$ANACONDA_INSTALLER
else
    echo "Using cached installer..."
fi

# Install Anaconda
echo "Installing Anaconda to $INSTALL_DIR..."
sudo bash $ANACONDA_INSTALLER -b -p "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"

# Configure conda to use conda-forge only (avoids ToS issues)
echo "Configuring conda to use conda-forge..."
sudo tee "$INSTALL_DIR/.condarc" > /dev/null <<'EOF'
channels:
  - conda-forge
envs_dirs:
  - ~/.conda/envs
pkgs_dirs:
  - ~/.conda/pkgs
auto_activate_base: false
channel_priority: strict
EOF

# Update conda using conda-forge
echo "Updating conda from conda-forge..."
sudo "$INSTALL_DIR/bin/conda" update -n base -c conda-forge conda -y

# Install commonly needed packages in base environment
echo "Installing essential packages in base environment..."
sudo "$INSTALL_DIR/bin/conda" install -n base -c conda-forge -y \
    numpy scipy pandas matplotlib jupyter ipython

# Create module file
echo "Creating module file..."
sudo tee "$MODULE_DIR/2025.06" > /dev/null <<EOF
#%Module1.0
##
## Anaconda 2025.06 modulefile
##
proc ModulesHelp { } {
    puts stderr "Adds Anaconda Python 2025.06 to your environment"
    puts stderr ""
    puts stderr "This installation uses conda-forge channel exclusively"
    puts stderr "to avoid Anaconda Terms of Service restrictions."
}

module-whatis "Anaconda Python Distribution 2025.06 (conda-forge)"

set anaconda_root $INSTALL_DIR

# Initialize conda when module is loaded
if { [module-info mode load] } {
    puts stdout "source \$anaconda_root/etc/profile.d/conda.sh;"
}

prepend-path PATH \$anaconda_root/bin
setenv CONDA_ROOT \$anaconda_root
setenv ANACONDA_HOME \$anaconda_root
EOF

# Set as default version (create proper .version file, not a symlink)
echo "Setting as default version..."
sudo tee "$MODULE_DIR/.version" > /dev/null <<'EOF'
#%Module1.0
set ModulesVersion "2025.06"
EOF

# Clean up
rm -f /tmp/$ANACONDA_INSTALLER

echo ""
echo "========================================="
echo "✓ Anaconda Module Installation Complete!"
echo "========================================="
echo ""
echo "Installation directory: $INSTALL_DIR"
echo "Module file: $MODULE_DIR/2025.06"
echo ""
echo "Configuration:"
echo "  - Using conda-forge channel exclusively"
echo "  - No Anaconda ToS restrictions"
echo "  - Base packages installed: numpy, scipy, pandas, matplotlib, jupyter"
echo ""
echo "Users can now:"
echo "  1. Load module: module load anaconda"
echo "  2. Check version: conda --version"
echo "  3. Create environments: conda create -n myenv python=3.10"
echo "  4. Install packages: conda install -c conda-forge <package>"
echo ""
echo "In SLURM jobs, add:"
echo "  module load anaconda"
echo "  conda activate myenv"
echo ""
echo "Test installation:"
echo "  source /etc/profile.d/modules.sh"
echo "  module load anaconda"
echo "  conda create -n test python=3.10 numpy -y"
echo "  conda activate test"
echo "  python -c 'import numpy; print(numpy.__version__)'"
echo ""
