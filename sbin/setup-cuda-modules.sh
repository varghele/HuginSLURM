#!/bin/bash
# File: /usr/local/sbin/setup-cuda-modules.sh
# Purpose: Install multiple CUDA versions and create module files

echo "========================================="
echo "CUDA Multi-Version Setup"
echo "========================================="

# Check and install build-essential if needed
echo "Checking for build tools..."
if ! command -v gcc &> /dev/null; then
    echo "Installing build-essential..."
    sudo apt-get update
    sudo apt-get install -y build-essential
fi

echo "GCC version: $(gcc --version | head -n1)"

# Function to install CUDA
install_cuda() {
    local version=$1
    local url=$2
    local short_version=$(echo "$version" | cut -d. -f1,2)
    local install_dir="/opt/cuda-${short_version}"

    echo ""
    echo "Installing CUDA ${version}..."

    # Check if already installed
    if [ -d "$install_dir" ] && [ -f "$install_dir/bin/nvcc" ]; then
        echo "  CUDA ${short_version} already installed at $install_dir"
        return 0
    fi

    # Download installer
    cd /tmp
    local installer=$(basename "$url")

    # Check if already downloaded
    if [ ! -f "$installer" ]; then
        echo "  Downloading $installer..."
        wget -q --show-progress "$url"

        if [ ! -f "$installer" ]; then
            echo "  ✗ ERROR: Failed to download $installer"
            return 1
        fi
    else
        echo "  Using cached $installer"
    fi

    # Install CUDA toolkit only (no driver, no samples)
    # Override GCC version check with --override flag
    echo "  Installing to $install_dir..."
    sudo sh "$installer" \
        --silent \
        --toolkit \
        --toolkitpath="$install_dir" \
        --no-opengl-libs \
        --override \
        2>&1 | tee /tmp/cuda-install-${short_version}.log

    # Check if installation succeeded
    if [ -f "$install_dir/bin/nvcc" ]; then
        echo "  ✓ CUDA ${short_version} installed successfully"
        # Clean up installer
        rm -f "$installer"
        return 0
    else
        echo "  ✗ ERROR: Installation failed"
        echo "  Check log: /tmp/cuda-install-${short_version}.log"
        return 1
    fi
}

# Function to create module file
create_cuda_module() {
    local version=$1
    local short_version=$(echo "$version" | cut -d. -f1,2)
    local install_dir="/opt/cuda-${short_version}"
    local module_file="/opt/modulefiles/cuda/${short_version}"

    # Only create module if CUDA is actually installed
    if [ ! -f "$install_dir/bin/nvcc" ]; then
        echo "  ⚠ Skipping module creation - CUDA not installed"
        return 1
    fi

    echo "  Creating module file for CUDA ${short_version}..."

    sudo tee "$module_file" > /dev/null <<EOF
#%Module1.0
##
## CUDA ${short_version} modulefile
##
proc ModulesHelp { } {
    puts stderr "Adds CUDA Toolkit ${short_version} to your environment"
}

module-whatis "CUDA Toolkit ${short_version}"

set cuda_root ${install_dir}

prepend-path PATH            \$cuda_root/bin
prepend-path LD_LIBRARY_PATH \$cuda_root/lib64
prepend-path LIBRARY_PATH    \$cuda_root/lib64
prepend-path CPATH           \$cuda_root/include
prepend-path MANPATH         \$cuda_root/doc/man

setenv CUDA_HOME \$cuda_root
setenv CUDA_ROOT \$cuda_root
setenv CUDA_PATH \$cuda_root
setenv CUDA_VERSION ${short_version}
EOF

    echo "  ✓ Module file created: $module_file"
}

# Install CUDA 11.8
install_cuda "11.8.0" "https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run"
create_cuda_module "11.8.0"

# Install CUDA 12.1
install_cuda "12.1.0" "https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run"
create_cuda_module "12.1.0"

# Install CUDA 12.4
install_cuda "12.4.0" "https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run"
create_cuda_module "12.4.0"

# Install CUDA 12.6
install_cuda "12.6.0" "https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda_12.6.0_560.28.03_linux.run"
create_cuda_module "12.6.0"

# Install CUDA 12.8
install_cuda "12.8.0" "https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_570.86.10_linux.run"
create_cuda_module "12.8.0"

# Install CUDA 12.9
install_cuda "12.9.1" "https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda_12.9.1_575.57.08_linux.run"
create_cuda_module "12.9.1"

# Set default CUDA version (12.4 is most stable)
echo ""
echo "Setting CUDA 12.4 as default..."
sudo tee /opt/modulefiles/cuda/.version > /dev/null <<'EOF'
#%Module1.0
set ModulesVersion "12.4"
EOF

echo ""
echo "========================================="
echo "✓ CUDA Setup Complete!"
echo "========================================="
echo ""
echo "Successfully installed CUDA versions:"
for dir in /opt/cuda-*; do
    if [ -f "$dir/bin/nvcc" ]; then
        version=$(basename "$dir" | sed 's/cuda-//')
        nvcc_version=$("$dir/bin/nvcc" --version | grep "release" | awk '{print $5}' | tr -d ',')
        echo "  ✓ CUDA $version (nvcc $nvcc_version)"
    fi
done

echo ""
echo "Module files created:"
ls /opt/modulefiles/cuda/ 2>/dev/null | grep -v "^\." | sed 's/^/  - cuda\//'

echo ""
echo "To use CUDA modules:"
echo "  1. Load modules: source /etc/profile.d/modules.sh"
echo "  2. List modules: module avail"
echo "  3. Load CUDA: module load cuda/12.4"
echo "  4. Test: nvcc --version"
echo ""
echo "In SLURM jobs, add:"
echo "  module load cuda/12.4"
echo "  nvcc --version"
echo ""
