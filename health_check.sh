#!/bin/bash
# health_check.sh - Checks CPU, Memory, and Disk usage health for an Ubuntu VM

EXPLAIN=false
if [[ "$1" == "explain" ]]; then
    EXPLAIN=true
fi

REASON=""
STATE="healthy"

# CPU Usage (%) - 1 minute average
CPU_USAGE=$(top -bn1 | grep '^%Cpu' | awk '{print 100-$8}')

# Memory Usage (%)
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
MEM_USAGE=$(awk -v used=$MEM_USED -v total=$MEM_TOTAL 'BEGIN { printf "%.2f", (used/total)*100 }')

# Disk Usage (%) - of /
DISK_USAGE=$(df --output=pcent / | tail -1 | tr -dc '0-9.')

# Check for unhealthy conditions (any > 60%)
if (( $(echo "$CPU_USAGE > 60" | bc -l) )) || \
   (( $(echo "$MEM_USAGE > 60" | bc -l) )) || \
   (( $(echo "$DISK_USAGE > 60" | bc -l) )); then
    STATE="unhealthy"
fi

if $EXPLAIN; then
    [[ $(echo "$CPU_USAGE > 60" | bc -l) -eq 1 ]] && REASON+="CPU usage is high ($CPU_USAGE%). "
    [[ $(echo "$MEM_USAGE > 60" | bc -l) -eq 1 ]] && REASON+="Memory usage is high ($MEM_USAGE%). "
    [[ $(echo "$DISK_USAGE > 60" | bc -l) -eq 1 ]] && REASON+="Disk usage is high ($DISK_USAGE%). "
    if [[ -z "$REASON" ]]; then
        REASON="All usage parameters are below 60%."
    fi
    echo "VM is $STATE. Reason: $REASON"
else
    echo "VM is $STATE."
fi

exit 0
