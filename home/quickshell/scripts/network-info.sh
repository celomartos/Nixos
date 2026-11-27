#!/usr/bin/env bash
set -u

iface=""
route="$(ip -4 route show default 2>/dev/null | head -n1)"
gateway="$(awk '{for (i=1;i<=NF;i++) if ($i=="via") {print $(i+1); exit}}' <<< "$route")"
iface="$(awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}' <<< "$route")"
if [[ -z "$iface" ]]; then
    iface="$(ip -o link show up 2>/dev/null | awk -F': ' '$2 != "lo" {sub(/@.*/, "", $2); print $2; exit}')"
fi

state="Offline"
type="—"
ipv4="—"
download="0 B/s"
upload="0 B/s"

if [[ -n "$iface" && -d "/sys/class/net/$iface" ]]; then
    [[ -n "$route" ]] && state="Online"
    if [[ "$iface" == *"tun"* || "$iface" == *"tap"* || "$iface" == *"wg"* || "$iface" == *"vpn"* || -d "/sys/class/net/$iface/wireguard" ]]; then
        type="VPN"
    elif [[ -d "/sys/class/net/$iface/wireless" ]]; then
        type="Wi-Fi"
    else
        type="Ethernet"
    fi
    ipv4="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}')"
    [[ -n "$ipv4" ]] || ipv4="—"

    rx="$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)"
    tx="$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)"
    state_file="${XDG_RUNTIME_DIR:-/tmp}/quickshell-network-${UID}-${iface//[^a-zA-Z0-9_.-]/_}"
    now="$(date +%s)"
    if [[ -r "$state_file" ]]; then
        read -r old_rx old_tx old_time < "$state_file" || true
        if [[ "${old_time:-}" =~ ^[0-9]+$ ]] && (( now > old_time )); then
            seconds=$((now - old_time))
            rx_rate=$(((rx - old_rx) / seconds))
            tx_rate=$(((tx - old_tx) / seconds))
            (( rx_rate < 0 )) && rx_rate=0
            (( tx_rate < 0 )) && tx_rate=0
            download="$(numfmt --to=iec-i --suffix=B/s "$rx_rate" 2>/dev/null || echo "${rx_rate} B/s")"
            upload="$(numfmt --to=iec-i --suffix=B/s "$tx_rate" 2>/dev/null || echo "${tx_rate} B/s")"
        fi
    fi
    printf '%s %s %s\n' "$rx" "$tx" "$now" > "$state_file"
fi

printf '{"state":"%s","type":"%s","interface":"%s","ipv4":"%s","gateway":"%s","download":"%s","upload":"%s"}\n' \
    "$state" "$type" "${iface:-—}" "$ipv4" "${gateway:-—}" "$download" "$upload"
