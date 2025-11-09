#!/bin/bash

# =====================================================
# Simple Linux Cybersecurity Script (Offline Capable)
# =====================================================
# Author: Josh
# Purpose: Update system, upgrade packages, create a new user,
#          apply basic hardening, and reboot the system.
# Notes: 
#   - Must be run as root (sudo)
#   - Works on both Ubuntu/Debian and CentOS/RHEL
#   - Offline updates assume packages are cached locally (no internet required)
# =====================================================

# -------------------------
# Check if running as root
# -------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

# -------------------------
# Ask for the new user name
# -------------------------
read -p "Enter the name of the new non-root user: " NEW_USER

# -------------------------
# Create a new user and set password
# -------------------------
echo "Creating user: $NEW_USER"
useradd -m -s /bin/bash "$NEW_USER"
echo "Please set a password for $NEW_USER"
passwd "$NEW_USER"

# -------------------------
# Update OS packages (offline)
# -------------------------
echo "Updating packages (offline if possible)..."

# For Debian/Ubuntu-based systems
if command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu system"
    apt-get update -o Acquire::http::No-Cache=True
    apt-get upgrade -y
    apt-get dist-upgrade -y

# For CentOS/RHEL-based systems
elif command -v yum >/dev/null 2>&1; then
    echo "Detected CentOS/RHEL system"
    yum makecache fast
    yum upgrade -y
else
    echo "Unsupported Linux distribution."
    exit 1
fi

# -------------------------
# Basic system hardening
# -------------------------
echo "Applying basic system hardening..."

# Disable root SSH login
if [ -f /etc/ssh/sshd_config ]; then
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart sshd
fi

# Enable firewall (simple rules)
if command -v ufw >/dev/null 2>&1; then
    echo "Enabling UFW firewall (Ubuntu/Debian)"
    ufw enable
    ufw default deny incoming
    ufw default allow outgoing
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "Enabling firewalld (CentOS/RHEL)"
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --set-default-zone=drop
    firewall-cmd --reload
fi

# -------------------------
# Reboot to apply changes
# -------------------------
echo "All done. Rebooting system to apply changes..."
sudo shutdown -r +10 "Scheduled reboot in 10 minutes. Save your work!"
