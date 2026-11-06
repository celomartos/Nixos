#!/usr/bin/env bash

CPU=$(sensors | awk '/Tctl/ {print $2}' | tr -d '+' | cut -d. -f1)

echo "${CPU}°C"

