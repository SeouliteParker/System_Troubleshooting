#!/bin/bash

LOG_FILE="$HOME/System_Troubleshooting/logs/monitor.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "TIME,PID,PPID,CPU(%),RSS(KB),MEM(%),STATUS" >> "$LOG_FILE"

while true; do
    TIME=$(date '+%F %T')

    # 필수 점검: 프로세스 비정상 시 종료
    if ! pgrep -x agent-leak-app- >/dev/null; then
        echo "[CRITICAL] agent-leak-app-x86 process not running" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 필수 점검: TCP 15034 LISTEN 확인
    if ! ss -ltnH | awk '$4 ~ /:15034$/ {found=1} END {exit !found}'; then
        echo "[CRITICAL] TCP 15034 not LISTEN" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 1. 프로세스별 CPU/메모리 수집
    ps -eo pid,ppid,%cpu,rss,%mem,stat,comm |
    awk -v t="$TIME" '$7 ~ /^agent-leak-app/ {
        print t","$1","$2","$3","$4","$5","$6
    }' >> "$LOG_FILE"

    # 2. 시스템 전체 자원 사용률
    read_cpu() {
    awk '/^cpu / {
        idle=$5+$6
        total=0
        for(i=2;i<=NF;i++) total+=$i
        print idle, total
        exit
    }' /proc/stat
}

read IDLE1 TOTAL1 < <(read_cpu)
sleep 1
read IDLE2 TOTAL2 < <(read_cpu)

CPU=$(awk -v i1="$IDLE1" -v i2="$IDLE2"           -v t1="$TOTAL1" -v t2="$TOTAL2"     'BEGIN {
        dt=t2-t1
        if(dt>0) printf "%.1f", 100*(1-(i2-i1)/dt)
        else print "0.0"
    }')
    MEM=$(free | awk '/Mem:/ {printf "%.1f",$3/$2*100}')
    DISK=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

    # 3. 방화벽 상태
    if command -v ufw >/dev/null 2>&1; then
        FW=$(sudo -n ufw status 2>/dev/null | head -n 1)
    elif command -v firewall-cmd >/dev/null 2>&1; then
        FW=$(firewall-cmd --state 2>/dev/null)
    else
        FW="unknown"
    fi

    echo "$TIME SYSTEM CPU:$CPU MEM:$MEM DISK:$DISK FIREWALL:$FW" >> "$LOG_FILE"

    # 4. 임계값 경고
    awk -v v="$CPU" 'BEGIN {exit !(v>20)}' &&
        echo "[WARNING] CPU over 20%" >> "$LOG_FILE"

    awk -v v="$MEM" 'BEGIN {exit !(v>10)}' &&
        echo "[WARNING] MEM over 10%" >> "$LOG_FILE"

    if [ "$DISK" -gt 80 ]; then
        echo "[WARNING] DISK over 80%" >> "$LOG_FILE"
    fi

    case "$FW" in
        *active*|running) ;;
        *) echo "[WARNING] Firewall inactive or unknown" >> "$LOG_FILE" ;;
    esac

    sleep 1
done
