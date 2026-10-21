#!/bin/bash
# Мониторинг ресурсов: раз в INTERVAL секунд дописывает в monitor.log
# снимок free -h, df -h и uptime с временной меткой.
#
# Запуск:  ./script.sh                    — бесконечно, остановка по Ctrl+C
#          MAX_ITERATIONS=3 ./script.sh   — сделать 3 снимка и выйти

set -u

INTERVAL=10                              # период снимков, секунд
LOG_FILE="${LOG_FILE:-monitor.log}"      # куда дописывать снимки
MAX_ITERATIONS="${MAX_ITERATIONS:-0}"    # 0 = без ограничения

REQUIRED_CMDS=(free df uptime date)

die() {
    echo "ОШИБКА: $*" >&2
    exit 1
}

# --- Проверки перед стартом ---

for cmd in "${REQUIRED_CMDS[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || die "команда '$cmd' не найдена"
done

[[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] \
    || die "MAX_ITERATIONS должно быть целым числом >= 0, получено '$MAX_ITERATIONS'"

LOG_DIR="$(dirname "$LOG_FILE")"
[ -d "$LOG_DIR" ] || die "каталог '$LOG_DIR' для лога не существует"
touch "$LOG_FILE" 2>/dev/null || die "нет прав на запись в '$LOG_FILE'"

# --- Аккуратная остановка по Ctrl+C / kill ---

on_stop() {
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') мониторинг остановлен ---" >> "$LOG_FILE"
    echo "Мониторинг остановлен, лог: $LOG_FILE"
    exit 0
}
trap on_stop INT TERM

# Выполнить команду под заголовком; при сбое записать ошибку и продолжить
run_section() {
    local title="$1"
    shift
    echo "[$title]"
    "$@" 2>&1
    local rc=$?
    [ "$rc" -eq 0 ] || echo "ОШИБКА: '$*' завершилась с кодом $rc"
}

take_snapshot() {
    {
        echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---"
        run_section "free -h" free -h
        run_section "df -h" df -h
        run_section "uptime" uptime
        echo
    } >> "$LOG_FILE"
}

# --- Основной цикл ---

echo "Мониторинг запущен: интервал ${INTERVAL} с, лог: $LOG_FILE, PID $$"

count=0
while true; do
    take_snapshot || die "не удалось записать снимок в '$LOG_FILE'"
    count=$((count + 1))

    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$count" -ge "$MAX_ITERATIONS" ]; then
        echo "Готово: снимков $count, лог: $LOG_FILE"
        break
    fi

    # sleep в фоне + wait, чтобы Ctrl+C срабатывал сразу, а не после сна
    sleep "$INTERVAL" &
    wait $!
done
