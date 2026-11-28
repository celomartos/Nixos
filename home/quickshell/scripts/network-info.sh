#!/usr/bin/env bash
set -u

iface=""
route="$(ip -4 route show default 2>/dev/null | head -n1)"
gateway="$(awk '{for (i=1;i<=NF;i++) if ($i=="via") {print $(i+1); exit}}' <<< "$route")"
iface="$(awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}' <<< "$route")"
internet_route="$(ip -4 route get 1.1.1.1 2>/dev/null | head -n1)"
internet_iface="$(awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}' <<< "$internet_route")"
if [[ -z "$iface" ]]; then
    # Without a default route, prefer an active physical adapter and skip
    # bridges, container links, and common virtual tunnel interfaces.
    iface="$(for path in /sys/class/net/*; do
        candidate="${path##*/}"
        [[ "$candidate" == "lo" || ! -e "$path/operstate" ]] && continue
        [[ "$(cat "$path/operstate" 2>/dev/null)" == "up" ]] || continue
        [[ -e "$path/device" ]] || continue
        [[ -d "$path/bridge" || -d "$path/wireguard" ]] && continue
        case "$candidate" in docker*|veth*|virbr*|br-*|br[0-9]*|lxc*|podman*|cni*|tun*|tap*|zt*|tailscale*|pvpnksintrf*) continue ;; esac
        printf '%s\n' "$candidate"
        break
    done)"
fi

state="Offline"
type="—"
ipv4="—"
download="0 B/s"
upload="0 B/s"

if [[ -n "$iface" && -d "/sys/class/net/$iface" ]]; then
    [[ -n "$route" ]] && state="Online"
    if [[ "$internet_iface" == "proton0" || "$internet_iface" == "tailscale0" || "$internet_iface" == zt* || "$internet_iface" == tun* || "$internet_iface" == tap* || "$internet_iface" == wg* || "$internet_iface" == *vpn* || ( -n "$internet_iface" && -d "/sys/class/net/$internet_iface/wireguard" ) ]]; then
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
    printf '%s %s %s\n' "$rx" "$tx" "$now" > "$state_file" 2>/dev/null || true
fi

printf '{"state":"%s","type":"%s","interface":"%s","ipv4":"%s","gateway":"%s","download":"%s","upload":"%s"}\n' \
    "$state" "$type" "${iface:-—}" "$ipv4" "${gateway:-—}" "$download" "$upload"
