#!/bin/bash

# SNetwork Troubleshooting Script
# Josh Codair
# Purpose: Diagnose network issues
#

# Create a timestamp 
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_FILE="/var/tmp/netreport_${TIMESTAMP}.txt"

# Start report header

echo "=== Network Diagnostic Report ===" > "$OUT_FILE"
echo "Date: $(date)" >> "$OUT_FILE"
echo "Hostname: $(hostname)" >> "$OUT_FILE"
echo "" >> "$OUT_FILE"

# Show all network interfaces
echo "=== Network Interfaces ===" >> "$OUT_FILE"
ip a >> "$OUT_FILE" 2>&1
echo "" >> "$OUT_FILE"

# Show routing table 
echo "=== Routing Table ===" >> "$OUT_FILE"
ip route show >> "$OUT_FILE" 2>&1
echo "" >> "$OUT_FILE"

# Display DNS settings
echo "=== /etc/resolv.conf ===" >> "$OUT_FILE"
cat /etc/resolv.conf 2>/dev/null >> "$OUT_FILE"
echo "" >> "$OUT_FILE"

# Show netplan config (Ubuntu systems)
echo "=== Netplan Configuration (/etc/netplan) ===" >> "$OUT_FILE"
if [ -d /etc/netplan ]; then
    ls -l /etc/netplan >> "$OUT_FILE"
    cat /etc/netplan/*.yaml 2>/dev/null >> "$OUT_FILE"
else
    echo "/etc/netplan not found" >> "$OUT_FILE"
fi
echo "" >> "$OUT_FILE"

# Show /etc/network/interfaces (Debian-style systems)

echo "=== /etc/network/interfaces ===" >> "$OUT_FILE"
if [ -f /etc/network/interfaces ]; then
    cat /etc/network/interfaces >> "$OUT_FILE"
else
    echo "/etc/network/interfaces not found" >> "$OUT_FILE"
fi
echo "" >> "$OUT_FILE"


# Connectivity test
echo "=== Test Connectivity ===" >> "$OUT_FILE"
echo "Ping 8.8.8.8 (IP connectivity):" >> "$OUT_FILE"
ping -c 2 8.8.8.8 >> "$OUT_FILE" 2>&1
echo "" >> "$OUT_FILE"

# Check name resolution
echo "Ping google.com (DNS test):" >> "$OUT_FILE"
ping -c 2 google.com >> "$OUT_FILE" 2>&1
echo "" >> "$OUT_FILE"

# Print completion message
echo "=== Done. Report saved to $OUT_FILE ==="
ls -l "$OUT_FILE"
