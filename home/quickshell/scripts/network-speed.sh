#!/usr/bin/env bash

set -u

offline() {
  printf '{"text":"󰖪 sem conexão","class":"offline","tooltip":"Sem conexão com a internet"}\n'
  exit 0
}

if ! command -v ip >/dev/null 2>&1; then
  offline
fi

interface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") {print $(i + 1); exit}}')
[[ -n "$interface" && -r "/sys/class/net/$interface/statistics/rx_bytes" ]] || offline

if [[ -r "/sys/class/net/$interface/operstate" ]] &&
   [[ "$(<"/sys/class/net/$interface/operstate")" == "down" ]]; then
  offline
fi

if ! { command -v curl >/dev/null 2>&1 && curl -fsS --connect-timeout 1 --max-time 2 https://connectivity-check.ubuntu.com/ >/dev/null 2>&1; } &&
   ! { command -v ping >/dev/null 2>&1 && ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1; }; then
  offline
fi

read -r rx_before tx_before < <(awk '{print $1, $2}' "/sys/class/net/$interface/statistics/rx_bytes" "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null | paste -sd' ')
sleep 1
read -r rx_after tx_after < <(awk '{print $1, $2}' "/sys/class/net/$interface/statistics/rx_bytes" "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null | paste -sd' ')

[[ -n "${rx_after:-}" && -n "${tx_after:-}" ]] || offline

download=$(( (rx_after - rx_before) > 0 ? (rx_after - rx_before) : 0 ))
upload=$(( (tx_after - tx_before) > 0 ? (tx_after - tx_before) : 0 ))

format_rate() {
  awk -v bytes="$1" 'BEGIN {
    if (bytes >= 1048576) printf "%.1f MB/s", bytes / 1048576
    else if (bytes >= 1024) printf "%.0f KB/s", bytes / 1024
    else printf "%.0f B/s", bytes
  }'
}

download_text=$(format_rate "$download")
upload_text=$(format_rate "$upload")
printf '{"text":"↓ %s  ↑ %s","class":"online","tooltip":"Download: %s\\nUpload: %s"}\n' \
  "$download_text" "$upload_text" "$download_text" "$upload_text"
