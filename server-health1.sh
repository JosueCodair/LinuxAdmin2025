#!/bin/bash
# =====================================================================
# SERVER HEALTH MONITOR SCRIPT
# Enhanced with more checks
#
# Josh Codair
# =====================================================================
# ---------------------------------------------------------------------
# VARIABLE
# ---------------------------------------------------------------------
LOG_DIR="/var/log/server-health"
mkdir -p "$LOG_DIR"

LOGFILE="$LOG_DIR/server_health_$(date +%F).log"

# ---------------------------------------------------------------------
# HEADER FUNCTION
# ---------------------------------------------------------------------
write_header() {
    echo "====================================================" >> "$LOGFILE"
    echo " SERVER HEALTH REPORT " >> "$LOGFILE"
    echo " Date: $(date)" >> "$LOGFILE"
    echo "====================================================" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# CPU CHECK
# ---------------------------------------------------------------------
check_cpu() {
    echo "[CPU CHECK]" >> "$LOGFILE"
    if command -v mpstat > /dev/null; then
        idle=$(mpstat 1 1 | awk '/Average/ {print $12}')
        used=$(awk "BEGIN {print 100 - $idle}")
        printf "CPU Usage: %.2f%%\n" "$used" >> "$LOGFILE"
    else
        used=$(top -bn1 | awk -F',' '/Cpu/ {print 100-$4}')
        printf "CPU Usage: %.2f%%\n" "$used" >> "$LOGFILE"
    fi
    # System load averages
    echo "Load Average (1,5,15 min): $(uptime | awk -F'load average:' '{print $2}')" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# MEMORY CHECK
# ---------------------------------------------------------------------
check_memory() {
    echo "[MEMORY CHECK]" >> "$LOGFILE"
    used=$(free -m | awk '/Mem:/ {print $3}')
    total=$(free -m | awk '/Mem:/ {print $2}')
    percent=$(awk "BEGIN {printf \"%.2f\", ($used/$total)*100}")
    echo "Memory Usage: $percent%" >> "$LOGFILE"

    # Swap usage
    swap_used=$(free -m | awk '/Swap:/ {print $3}')
    swap_total=$(free -m | awk '/Swap:/ {print $2}')
    swap_percent=$(awk "BEGIN {if($swap_total>0) printf \"%.2f\", ($swap_used/$swap_total)*100; else print 0}")
    echo "Swap Usage: $swap_used MB / $swap_total MB ($swap_percent%)" >> "$LOGFILE"

    if (( $(echo "$percent > 85" | bc -l) )); then
        echo "WARNING: Memory usage is high." >> "$LOGFILE"
    fi
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# DISK CHECK
# ---------------------------------------------------------------------
check_disk() {
    echo "[DISK CHECK]" >> "$LOGFILE"
    df -h --output=source,pcent,target | grep '^/' >> "$LOGFILE"
    # Optional: Disk I/O stats
    if command -v iostat > /dev/null; then
        echo "" >> "$LOGFILE"
        echo "Disk I/O Stats:" >> "$LOGFILE"
        iostat -dx 1 1 >> "$LOGFILE"
    fi
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# NETWORK CHECK
# ---------------------------------------------------------------------
check_network() {
    echo "[NETWORK CHECK]" >> "$LOGFILE"
    if ping -c1 -W1 8.8.8.8 > /dev/null 2>&1; then
        echo "Network Status: ONLINE" >> "$LOGFILE"
    else
        echo "Network Status: OFFLINE" >> "$LOGFILE"
    fi
    # Show active network connections
    echo "Active Network Connections:" >> "$LOGFILE"
    ss -tuln >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# PROCESS CHECK
# ---------------------------------------------------------------------
check_processes() {
    echo "[PROCESS CHECK]" >> "$LOGFILE"
    # Top 5 memory-consuming processes
    echo "Top 5 memory-consuming processes:" >> "$LOGFILE"
    ps aux --sort=-%mem | head -n 6 >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    # Top 5 CPU-consuming processes
    echo "Top 5 CPU-consuming processes:" >> "$LOGFILE"
    ps aux --sort=-%cpu | head -n 6 >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# SERVICE CHECK
# ---------------------------------------------------------------------
check_services() {
    echo "[SERVICE CHECK]" >> "$LOGFILE"
    echo "Enabled services:" >> "$LOGFILE"
    systemctl list-unit-files --type=service | grep enabled >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# SECURITY CHECK
# ---------------------------------------------------------------------
check_security() {
    echo "[SECURITY CHECK]" >> "$LOGFILE"
    # SSH root login
    ssh_root=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
    echo "SSH Root Login: $ssh_root" >> "$LOGFILE"

    # UFW/Firewalld status
    if command -v ufw > /dev/null; then
        echo "UFW Status:" >> "$LOGFILE"
        ufw status verbose >> "$LOGFILE"
    elif command -v firewall-cmd > /dev/null; then
        echo "Firewalld Status:" >> "$LOGFILE"
        firewall-cmd --state >> "$LOGFILE"
    fi
    echo "" >> "$LOGFILE"
}

# ---------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------
summary() {
    echo "Health report saved to: $LOGFILE"
}

# ---------------------------------------------------------------------
# MAIN FUNCTION
# ---------------------------------------------------------------------
main() {
    write_header
    check_cpu
    check_memory
    check_disk
    check_network
    check_processes
    check_services
    check_security
    summary
}

main
exit 0
