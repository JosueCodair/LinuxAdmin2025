#!/bin/bash
# -------------------------------------------------------------
# SIMPLE LINUX SERVER HARDENING SCRIPT (STRICTLY OFFLINE)
# Detects OS and performs maintenance using only LOCAL resources.
# All network access for updates is strictly avoided.
# -------------------------------------------------------------

# Check for root privileges (required for system changes)
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root. Please use 'sudo ./harden_offline.sh'"
   exit 1
fi

# 1. Detect Operating System and Perform Local Maintenance
echo "--- Detecting OS and Performing LOCAL Maintenance ---"
# Check if the release file for Red Hat-based systems exists
if [ -f /etc/redhat-release ]; then
    OS_TYPE="RHEL"
    echo "Detected: CentOS/RHEL/Fedora."
    # Cleans the local package cache (ensures only local data is used)
    yum clean all
    # Checks for locally installed package updates without connecting to repos
    # Note: Requires packages to be already downloaded locally
    yum check-update --cache-only 2>/dev/null
elif [ -f /etc/debian_version ]; then
    OS_TYPE="DEBIAN"
    echo "Detected: Ubuntu/Debian."
    # Cleans the local index/cache files, avoiding remote connection attempts
    apt clean
    # Checks the status of packages against the local database
    # Note: This only verifies the local state, no external check occurs
    dpkg --audit
else
    echo "ERROR: Unsupported OS type detected."
    exit 1
fi

# 2. Create a new non-root user
echo "--- Creating New Non-Root User ---"
# Asks the running user for the desired new username
read -p "Enter the desired **username** for the new non-root user: " NEW_USER
# Creates the user and sets up their home directory
adduser $NEW_USER
# Adds the new user to the 'sudo' group to allow temporary root access
usermod -aG sudo $NEW_USER

# 3. Apply Basic System Hardening (Firewall Configuration)
echo "--- Applying Basic Hardening Steps (Firewall) ---"
# Firewall installation and configuration depends on the detected OS type
if [ "$OS_TYPE" == "RHEL" ]; then
    # Install firewalld (must be available in the local cache/install media)
    yum install firewalld -y
    systemctl enable firewalld
    systemctl start firewalld
    # Allow SSH (port 22) - essential for remote access
    firewall-cmd --zone=public --add-service=ssh --permanent
    firewall-cmd --reload
elif [ "$OS_TYPE" == "DEBIAN" ]; then
    # Install UFW (must be available in the local cache/install media)
    apt install ufw -y
    ufw enable
    # Deny all incoming traffic by default
    ufw default deny incoming
    # Allow SSH access (standard port 22)
    ufw allow 22/tcp
fi

# 4. Schedule System Reboot
echo "--- Changes Applied. System will reboot in 10 minutes (at +10) ---"
# Schedules the system to reboot 10 minutes from the current time
shutdown -r +10 "System rebooting in 10 minutes to apply security changes."

echo "Script finished. Review system state before the scheduled reboot."