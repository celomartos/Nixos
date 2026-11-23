#!/usr/bin/env bash

set -u

offline() {
    printf 'Offline\n'
    exit 0
}

online() {
    printf 'Online\n'
    exit 0
}

# Check default network route
command -v ip >/dev/null 2>&1 || offline

interface="$(
    ip route get 1.1.1.1 2>/dev/null |
    awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }'
)"

[[ -n "$interface" ]] || offline

# Check interface state
operstate="/sys/class/net/$interface/operstate"

if [[ -r "$operstate" ]] && [[ "$(<"$operstate")" == "down" ]]; then
    offline
fi

# Check internet connectivity
if command -v curl >/dev/null 2>&1 &&
   curl -fsS --connect-timeout 1 --max-time 2 \
   https://connectivity-check.ubuntu.com/ >/dev/null 2>&1; then
    online
fi

if command -v ping >/dev/null 2>&1 &&
   ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1; then
    online
fi

offline
