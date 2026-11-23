#!/usr/bin/env bash

set -uo pipefail
export LC_ALL=C
shopt -s nullglob

proc_root="${PROC_ROOT:-/proc}"
sys_root="${SYS_ROOT:-/sys}"

# ------------------------------------------------------------
# CPU usage
# ------------------------------------------------------------

read_cpu_times() {
    local label user nice system idle iowait irq softirq steal guest guest_nice

    read -r label user nice system idle iowait irq softirq steal guest guest_nice \
        < "$proc_root/stat" || return 1

    user=${user:-0}
    nice=${nice:-0}
    system=${system:-0}
    idle=${idle:-0}
    iowait=${iowait:-0}
    irq=${irq:-0}
    softirq=${softirq:-0}
    steal=${steal:-0}

    cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    cpu_idle=$((idle + iowait))
}

# ------------------------------------------------------------
# RAM usage
# ------------------------------------------------------------

read_memory() {
    local key value unit total=0 available=0

    while read -r key value unit; do
        case "$key" in
            MemTotal:) total=${value:-0} ;;
            MemAvailable:) available=${value:-0} ;;
        esac
    done < "$proc_root/meminfo"

    memory_total=$((total * 1024))
    memory_used=$(((total - available) * 1024))

    if (( total > 0 )); then
        memory_percent=$(((total - available) * 100 / total))
    else
        memory_percent=""
    fi
}

# ------------------------------------------------------------
# CPU temperature (AMD k10temp / zenpower)
# ------------------------------------------------------------

read_cpu_temperature() {
    local hwmon name temp_file label_file label raw
    cpu_temp=""

    for hwmon in "$sys_root"/class/hwmon/hwmon*; do
        [[ -r "$hwmon/name" ]] || continue

        IFS= read -r name < "$hwmon/name"

        [[ "$name" == "k10temp" || "$name" == zenpower* ]] || continue

        for temp_file in "$hwmon"/temp*_input; do
            [[ -r "$temp_file" ]] || continue

            label_file="${temp_file%_input}_label"
            label=""

            if [[ -r "$label_file" ]]; then
                IFS= read -r label < "$label_file"
            fi

            if [[ "$label" == "Tctl" || "$label" == "Tdie" || ( -z "$label" && "$temp_file" == "$hwmon/temp1_input" ) ]]; then
                IFS= read -r raw < "$temp_file"

                if [[ "$raw" =~ ^-?[0-9]+$ ]]; then
                    cpu_temp=$((raw / 1000))
                    return
                fi
            fi
        done
    done
}

# ------------------------------------------------------------
# AMD GPU usage and temperature
# ------------------------------------------------------------

read_gpu_metrics() {
    local card device driver hwmon temp_file raw

    gpu_usage=""
    gpu_temp=""

    for card in "$sys_root"/class/drm/card[0-9]*; do
        device="$card/device"

        [[ -d "$device" && -L "$device/driver" ]] || continue

        driver="$(basename "$(readlink -f "$device/driver" 2>/dev/null)")"

        [[ "$driver" == "amdgpu" ]] || continue

        if [[ -r "$device/gpu_busy_percent" ]]; then
            IFS= read -r raw < "$device/gpu_busy_percent"

            if [[ "$raw" =~ ^[0-9]+$ ]]; then
                gpu_usage=$((raw > 100 ? 100 : raw))
            fi
        fi

        for hwmon in "$device"/hwmon/hwmon*; do
            for temp_file in "$hwmon"/temp*_input; do
                [[ -r "$temp_file" ]] || continue

                IFS= read -r raw < "$temp_file"

                if [[ "$raw" =~ ^-?[0-9]+$ ]]; then
                    gpu_temp=$((raw / 1000))
                    break 2
                fi
            done
        done

        break
    done
}

# ------------------------------------------------------------
# Root filesystem usage
# ------------------------------------------------------------

read_storage() {
    local values

    storage_total=""
    storage_used=""
    storage_percent=""

    values="$(df -P -B1 / 2>/dev/null |
        awk 'NR == 2 { gsub(/%/, "", $5); print $2, $3, $5 }')"

    read -r storage_total storage_used storage_percent <<< "$values"

    storage_total=${storage_total:-}
    storage_used=${storage_used:-}
    storage_percent=${storage_percent:-}
}

# ------------------------------------------------------------
# Disk I/O (physical devices backing the root filesystem)
# ------------------------------------------------------------

get_root_disks() {
    local source name type

    command -v findmnt >/dev/null 2>&1 || return 0
    command -v lsblk >/dev/null 2>&1 || return 0

    source="$(findmnt -n -o SOURCE / 2>/dev/null)"
    source="${source%%\[*}"

    [[ -n "$source" && -b "$source" ]] || return 0

    while read -r name type; do
        [[ "$type" == "disk" ]] && printf '%s\n' "$name"
    done < <(lsblk -s -n -r -o NAME,TYPE "$source" 2>/dev/null)
}

read_disk_io() {
    local disk stat_file sectors_read sectors_written

    disk_read_bytes=0
    disk_write_bytes=0

    for disk in "${root_disks[@]}"; do
        stat_file="$sys_root/block/$disk/stat"

        [[ -r "$stat_file" ]] || continue

        read -r _ _ sectors_read _ _ _ sectors_written _ < "$stat_file" || continue

        [[ "${sectors_read:-}" =~ ^[0-9]+$ ]] || continue
        [[ "${sectors_written:-}" =~ ^[0-9]+$ ]] || continue

        # Linux reports these counters in 512-byte sectors.
        disk_read_bytes=$((disk_read_bytes + sectors_read * 512))
        disk_write_bytes=$((disk_write_bytes + sectors_written * 512))
    done
}

# ------------------------------------------------------------
# Network speed (active route interface)
# ------------------------------------------------------------

get_default_interface() {
    local route i
    local -a fields

    command -v ip >/dev/null 2>&1 || return 0

    route="$(ip route get 1.1.1.1 2>/dev/null || true)"
    read -r -a fields <<< "$route"

    for ((i = 0; i < ${#fields[@]}; i++)); do
        if [[ "${fields[i]}" == "dev" ]] && (( i + 1 < ${#fields[@]} )); then
            printf '%s' "${fields[i + 1]}"
            return 0
        fi
    done
}

# ------------------------------------------------------------
# JSON helper
# ------------------------------------------------------------

json_number() {
    if [[ "${1:-}" =~ ^-?[0-9]+$ ]]; then
        printf '%s' "$1"
    else
        printf 'null'
    fi
}

# Initial CPU sample
read_cpu_times || true

previous_cpu_total=${cpu_total:-0}
previous_cpu_idle=${cpu_idle:-0}

previous_interface=""
previous_rx=0
previous_tx=0

# Initial disk I/O sample
root_disks=()
mapfile -t root_disks < <(get_root_disks)

previous_disk_read=0
previous_disk_write=0

read_disk_io

previous_disk_read=$disk_read_bytes
previous_disk_write=$disk_write_bytes

# ------------------------------------------------------------
# Monitoring loop
# ------------------------------------------------------------

while true; do
    sleep 1

    # CPU
    cpu_usage=""

    if read_cpu_times; then
        total_delta=$((cpu_total - previous_cpu_total))
        idle_delta=$((cpu_idle - previous_cpu_idle))

        if (( total_delta > 0 )); then
            cpu_usage=$(((total_delta - idle_delta) * 100 / total_delta))

            (( cpu_usage < 0 )) && cpu_usage=0
            (( cpu_usage > 100 )) && cpu_usage=100
        fi

        previous_cpu_total=$cpu_total
        previous_cpu_idle=$cpu_idle
    fi

    # Other system metrics
    read_memory
    read_cpu_temperature
    read_gpu_metrics
    read_storage

    # Disk I/O speed (bytes read/written during the last interval)
    read_disk_io

    disk_read=$((disk_read_bytes - previous_disk_read))
    disk_write=$((disk_write_bytes - previous_disk_write))

    (( disk_read < 0 )) && disk_read=0
    (( disk_write < 0 )) && disk_write=0

    previous_disk_read=$disk_read_bytes
    previous_disk_write=$disk_write_bytes

    # Network
    network_connected=0
    network_down=0
    network_up=0

    current_interface="$(get_default_interface)"

    if [[ -n "$current_interface" ]]; then
        rx_file="$sys_root/class/net/$current_interface/statistics/rx_bytes"
        tx_file="$sys_root/class/net/$current_interface/statistics/tx_bytes"

        if [[ -r "$rx_file" && -r "$tx_file" ]]; then
            IFS= read -r current_rx < "$rx_file"
            IFS= read -r current_tx < "$tx_file"

            if [[ "$current_interface" == "$previous_interface" &&
                  "$current_rx" =~ ^[0-9]+$ &&
                  "$current_tx" =~ ^[0-9]+$ ]]; then

                network_down=$((current_rx - previous_rx))
                network_up=$((current_tx - previous_tx))

                (( network_down < 0 )) && network_down=0
                (( network_up < 0 )) && network_up=0
            fi

            network_connected=1
            previous_interface="$current_interface"
            previous_rx="$current_rx"
            previous_tx="$current_tx"
        else
            previous_interface=""
            previous_rx=0
            previous_tx=0
        fi
    else
        previous_interface=""
        previous_rx=0
        previous_tx=0
    fi

    # Send one JSON sample per second
    printf '{"cpu_usage":%s,"cpu_temp":%s,"memory_used":%s,"memory_total":%s,"memory_percent":%s,"gpu_usage":%s,"gpu_temp":%s,"storage_used":%s,"storage_total":%s,"storage_percent":%s,"disk_read":%s,"disk_write":%s,"network_down":%s,"network_up":%s,"network_connected":%s}\n' \
        "$(json_number "$cpu_usage")" \
        "$(json_number "$cpu_temp")" \
        "$(json_number "$memory_used")" \
        "$(json_number "$memory_total")" \
        "$(json_number "$memory_percent")" \
        "$(json_number "$gpu_usage")" \
        "$(json_number "$gpu_temp")" \
        "$(json_number "$storage_used")" \
        "$(json_number "$storage_total")" \
        "$(json_number "$storage_percent")" \
        "$(json_number "$disk_read")" \
        "$(json_number "$disk_write")" \
        "$(json_number "$network_down")" \
        "$(json_number "$network_up")" \
        "$([[ "$network_connected" == 1 ]] && printf true || printf false)"
done

