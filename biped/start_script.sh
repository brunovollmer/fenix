#!/bin/bash

rfkill block bluetooth
sleep 3
rfkill unblock bluetooth
sleep 3
bluetoothctl power on

# wait for internet connection
while true; do
  if ping -q -c 1 -W 1 google.com >/dev/null; then
    echo "connected!"

    # kudelski

    rm -f "$0"
    rm -f "/etc/systemd/system/start_script.service"
    break
  else
    sleep 5
  fi
done