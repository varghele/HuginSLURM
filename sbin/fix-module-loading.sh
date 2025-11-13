#!/bin/bash
# File: /usr/local/sbin/fix-module-loading.sh
# Purpose: Ensure modules load automatically for all users

echo "Fixing automatic module loading..."

# 1. Add to system-wide bashrc
if ! grep -q "modules.sh" /etc/bash.bashrc; then
    echo "Adding to /etc/bash.bashrc..."
    sudo tee -a /etc/bash.bashrc > /dev/null <<'EOF'

# Initialize Environment Modules for all users
if [ -f /etc/profile.d/modules.sh ]; then
    source /etc/profile.d/modules.sh
fi
EOF
fi

# 2. Add to system-wide profile (for login shells)
if ! grep -q "modules.sh" /etc/profile; then
    echo "Adding to /etc/profile..."
    sudo tee -a /etc/profile > /dev/null <<'EOF'

# Initialize Environment Modules
if [ -f /etc/profile.d/modules.sh ]; then
    . /etc/profile.d/modules.sh
fi
EOF
fi

# 3. Fix for existing users
echo "Fixing existing user accounts..."
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        bashrc="$user_home/.bashrc"

        if [ -f "$bashrc" ] && ! grep -q "modules.sh" "$bashrc"; then
            echo "  Updating $username's .bashrc..."
            sudo tee -a "$bashrc" > /dev/null <<'EOF'

# Initialize Environment Modules
if [ -f /etc/profile.d/modules.sh ]; then
    source /etc/profile.d/modules.sh
fi
EOF
            sudo chown "$username:$username" "$bashrc"
        fi
    fi
done

echo ""
echo "✓ Module loading fixed!"
echo ""
echo "Users should now have modules available automatically."
echo "They may need to log out and back in for changes to take effect."
