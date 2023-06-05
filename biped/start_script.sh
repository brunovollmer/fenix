#!/bin/bash

COPILOT_ENV_PATH="/etc/copilot/"
COPILOT_ENV_FILEPATH="$COPILOT_ENV_PATH/copilot.env"

rfkill block bluetooth
sleep 3
rfkill unblock bluetooth
sleep 3
bluetoothctl power on

create_env_file () {
  mkdir -p $COPILOT_ENV_PATH
  touch $COPILOT_ENV_FILEPATH
  echo "export COPILOT_DEVICE_NAME=bipedxxx" >> $COPILOT_ENV_FILEPATH
  echo "export COPILOT_CAMERA_0=0" >> $COPILOT_ENV_FILEPATH
  echo "export COPILOT_CAMERA_1=0" >> $COPILOT_ENV_FILEPATH
  echo "export COPILOT_CAMERA_2=0" >> $COPILOT_ENV_FILEPATH
  echo "export DEVICE_TYPE=edge_2" >> $COPILOT_ENV_FILEPATH
}

create_env_file

# wait for internet connection for doing tasks
while true; do
  if ping -q -c 1 -W 1 google.com >/dev/null; then
    echo "connected!"

    # kudelski
    break
  else
    sleep 5
  fi
done

rm -f "$0"
rm -f "/etc/systemd/system/start_script.service"