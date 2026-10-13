#!/bin/bash

LOG_FILE="$HOME/System_Troubleshooting/logs/monitor.log"

echo "TIME,PID,PPID,CPU(%),RSS(KB),MEM(%),STATUS" > "$LOG_FILE"

while true; do
    ps -eo pid,ppid,%cpu,rss,%mem,stat,comm |
    awk -v t="$(date '+%F %T')" \
    '$7 ~ /^agent-leak-app/ {
        print t","$1","$2","$3","$4","$5","$6
    }' >> "$LOG_FILE"

    sleep 1
done
