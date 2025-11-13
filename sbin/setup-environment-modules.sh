#!/bin/bash
# File: /usr/local/sbin/setup-environment-modules.sh
# Purpose: Install and configure Environment Modules

echo "========================================="
echo "Installing Environment Modules"
echo "========================================="

# Install modules package
sudo apt-get update
sudo apt-get install -y environment-modules

# Create initialization script for all users
sudo tee /etc/profile.d/modules.sh > /dev/null <<'EOF'
# Environment Modules initialization
if [ -f /usr/share/modules/init/bash ]; then
    source /usr/share/modules/init/bash
fi
EOF

# Configure module path
sudo tee /usr/share/modules/init/.modulespath > /dev/null <<'EOF'
/opt/modulefiles
EOF

echo ""
echo "✓ Environment Modules installed!"
echo ""
echo "Users can now use:"
echo "  module avail       - List available modules"
echo "  module load cuda   - Load a module"
echo "  module list        - Show loaded modules"
echo ""
