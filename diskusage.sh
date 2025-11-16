#!/bin/bash
# Josh Codair
# Simple Linux Disk & Large File Troubleshooter
# Purpose: Help diagnose disk usage, large files, and potential

# Check if the script is run as root. Exit if not.

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Create output file with timestamp

OUT="/var/tmp/diskusage_$(date +%Y%m%d_%H%M%S).txt"

# Basic header for the report

echo "Disk & Large File Troubleshooter" > "$OUT"
echo "Generated: $(date)" >> "$OUT"
echo "===================================" >> "$OUT"

# Show disk usage
echo -e "\n=== Disk usage ===" >> "$OUT"
df -hT / >> "$OUT"

# List the top 20 biggest files
echo -e "\n=== Top 20 largest files in /var/log and /tmp ===" >> "$OUT"
du -ah /var/log /tmp 2>/dev/null | sort -hr | head -n 20 >> "$OUT"

# Check if the system is set to force an fsck at boot
echo -e "\n=== Check for /forcefsck ===" >> "$OUT"
if [ -f /forcefsck ]; then
    echo "/forcefsck exists" >> "$OUT"
else
    echo "/forcefsck not found" >> "$OUT"
fi

# Show the first 10 lines of logrotate
echo -e "\n=== /etc/logrotate.conf preview (first 10 lines) ===" >> "$OUT"
head -n 10 /etc/logrotate.conf 2>/dev/null >> "$OUT"

# Show recently modified files
echo -e "\n=== Recently modified files in /var/log and /tmp (last 60 mins) ===" >> "$OUT"
find /var/log /tmp -type f -mmin -60 -ls 2>/dev/null | head -n 20 >> "$OUT"

# Print completion message
echo -e "\nTroubleshooting complete. Results saved to $OUT"
echo "You can view with: less $OUT or cat $OUT"
