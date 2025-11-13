#!/bin/bash
# remove-slurm-user.sh - Safe user removal script

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 alice"
    exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "Error: User $USERNAME does not exist"
    exit 1
fi

echo "========================================="
echo "Removing SLURM user: $USERNAME"
echo "========================================="
echo ""

# Step 1: Cancel all running jobs
echo "Step 1: Canceling all jobs for $USERNAME..."
RUNNING_JOBS=$(squeue -u "$USERNAME" -h -o "%i" | wc -l)
if [ $RUNNING_JOBS -gt 0 ]; then
    echo "  Found $RUNNING_JOBS running/pending jobs"
    sudo scancel -u "$USERNAME"
    echo "  All jobs canceled"
else
    echo "  No running jobs found"
fi

# Step 2: Check disk usage before removal
echo ""
echo "Step 2: Checking disk usage..."
echo "  Home directory:"
sudo du -sh /home/"$USERNAME" 2>/dev/null || echo "  (not found)"
echo "  HDD storage:"
sudo du -sh /mnt/hdd/users/"$USERNAME" 2>/dev/null || echo "  (not found)"

# Step 3: Ask for confirmation
echo ""
read -p "Do you want to DELETE all data for user $USERNAME? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted. User $USERNAME was NOT removed."
    exit 0
fi

# Step 4: Archive user data (optional)
echo ""
read -p "Do you want to ARCHIVE user data before deletion? (yes/no): " ARCHIVE

if [ "$ARCHIVE" = "yes" ]; then
    ARCHIVE_DIR="/root/user_archives"
    sudo mkdir -p "$ARCHIVE_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    echo "  Archiving to $ARCHIVE_DIR/${USERNAME}_${TIMESTAMP}.tar.gz"

    sudo tar -czf "$ARCHIVE_DIR/${USERNAME}_${TIMESTAMP}.tar.gz" \
        -C /home "$USERNAME" \
        -C /mnt/hdd/users "$USERNAME" 2>/dev/null

    echo "  Archive created: $ARCHIVE_DIR/${USERNAME}_${TIMESTAMP}.tar.gz"
fi

# Step 5: Remove HDD storage
echo ""
echo "Step 3: Removing HDD storage..."
if [ -d "/mnt/hdd/users/$USERNAME" ]; then
    sudo rm -rf "/mnt/hdd/users/$USERNAME"
    echo "  HDD storage removed"
else
    echo "  No HDD storage found"
fi

# Step 6: Remove user account and home directory
echo ""
echo "Step 4: Removing user account..."
sudo userdel -r "$USERNAME" 2>/dev/null
echo "  User account and home directory removed"

# Step 7: Remove any remaining processes
echo ""
echo "Step 5: Cleaning up any remaining processes..."
sudo pkill -u "$USERNAME" 2>/dev/null || echo "  No processes found"

# Step 8: Clean up quotas
echo ""
echo "Step 6: Removing disk quotas..."
sudo setquota -u "$USERNAME" 0 0 0 0 / 2>/dev/null
sudo setquota -u "$USERNAME" 0 0 0 0 /mnt/hdd 2>/dev/null
echo "  Quotas removed"

echo ""
echo "========================================="
echo "✓ User $USERNAME has been removed"
echo "========================================="

if [ "$ARCHIVE" = "yes" ]; then
    echo ""
    echo "User data archived to:"
    echo "  $ARCHIVE_DIR/${USERNAME}_${TIMESTAMP}.tar.gz"
fi

echo ""