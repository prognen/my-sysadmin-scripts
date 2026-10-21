#!/bin/bash
# Поднимает учебные RAID 1 и LVM на loop-устройствах после перезагрузки:
# loop-устройства не переживают ребут, а файлы-диски в /mnt/raid-lab остаются.
# Повторный запуск безопасен: уже сделанные шаги пропускаются.
#
# Установка: /usr/local/sbin/storage-up.sh, запускается службой storage-up.service

set -euo pipefail

LAB_DIR=/mnt/raid-lab
MD_DEV=/dev/md0
VG=vg_data
LV=lv_logs

log() { echo "storage-up: $*" >&2; }
die() { log "ОШИБКА: $*"; exit 1; }

[ "$(id -u)" -eq 0 ] || die "нужны права root"

# Подключить файл как loop-устройство (если ещё не подключён) и вывести имя устройства
attach() {
    local img="$LAB_DIR/$1" dev
    [ -f "$img" ] || die "нет файла $img"
    dev=$(losetup -j "$img" | cut -d: -f1 | head -n1)
    if [ -z "$dev" ]; then
        dev=$(losetup -fP --show "$img")
        log "$img -> $dev"
    else
        log "$img уже подключён как $dev"
    fi
    echo "$dev"
}

# Имя массива, в который уже входит устройство (udev может собрать его сам)
md_of() {
    awk -v d="$(basename "$1")[" '/^md/ && index($0, d) { print "/dev/" $1 }' /proc/mdstat
}

mount_once() {
    local dev="$1" dir="$2"
    mkdir -p "$dir"
    if mountpoint -q "$dir"; then
        log "$dir уже смонтирован"
    else
        mount "$dev" "$dir"
        log "$dev -> $dir"
    fi
}

# --- loop-устройства ---
LOOP1=$(attach disk1.img)
LOOP2=$(attach disk2.img)
LOOP3=$(attach disk3.img)

# --- RAID 1 ---
MD=$(md_of "$LOOP1")
if [ -z "$MD" ]; then
    mdadm --assemble "$MD_DEV" "$LOOP1" "$LOOP2"
    MD="$MD_DEV"
    log "массив $MD собран из $LOOP1 и $LOOP2"
else
    log "массив уже собран: $MD"
    # частично собранный автоматически массив нужно запустить вручную
    if grep -q "^$(basename "$MD") : inactive" /proc/mdstat; then
        mdadm --run "$MD"
    fi
fi
mount_once "$MD" /mnt/raid

# --- LVM ---
vgchange -ay "$VG" >/dev/null
mount_once "/dev/$VG/$LV" /mnt/logs

log "готово"
