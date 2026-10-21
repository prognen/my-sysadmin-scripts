#!/bin/bash
# Мониторинг ресурсов: раз в INTERVAL секунд дописывает в monitor.log
# снимок free -h, df -h и uptime с временной меткой.

INTERVAL=10
LOG_FILE="monitor.log"

while true; do
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"
    free -h >> "$LOG_FILE"
    df -h >> "$LOG_FILE"
    uptime >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    sleep "$INTERVAL"
done
