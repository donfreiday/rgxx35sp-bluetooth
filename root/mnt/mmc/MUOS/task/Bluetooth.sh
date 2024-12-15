#!/bin/sh

poll_devices() {
  bluetoothctl --timeout 60 scan on >/dev/null &
  while true; do
    devices=$(bluetoothctl devices)
    echo "$devices" >/tmp/bluetooth_devices
    sleep 10
  done &
}

print_devices() {
  clear
  echo "Available Bluetooth devices:"
  index=0
  echo "$devices" | while read -r line; do
    if [ "$index" -eq "$selected_index" ]; then
      echo "* $line"
    else
      echo "  $line"
    fi
    index=$((index + 1))
  done
}

connect_device() {
  device_mac=$1
  echo "Attempting to connect to $device_mac..."
  bluetoothctl connect "$device_mac"
  sleep 5
}

disconnect_device() {
  device_mac=$1
  echo "Attempting to disconnect from $device_mac..."
  bluetoothctl remove "$device_mac"
  sleep 5
}

main() {
  poll_devices
  selected_index=0

  evtest /dev/input/event1 | while read -r line; do
    devices=$(cat /tmp/bluetooth_devices)
    device_macs=$(echo "$devices" | awk '{print $2}')

    case "$line" in
    *"type 3 (EV_ABS), code 17 (ABS_HAT0Y), value -1"*) # Up
      selected_index=$((selected_index - 1))
      if [ "$selected_index" -lt 0 ]; then
        selected_index=$(echo "$device_macs" | wc -l)
        selected_index=$((selected_index - 1))
      fi
      ;;
    *"type 3 (EV_ABS), code 17 (ABS_HAT0Y), value 1"*) # Down
      selected_index=$((selected_index + 1))
      if [ "$selected_index" -ge "$(echo "$device_macs" | wc -l)" ]; then
        selected_index=0
      fi
      ;;
    *"type 1 (EV_KEY), code 307 (BTN_NORTH)"*) # X
      selected_mac=$(echo "$devices" | sed -n "$((selected_index + 1))p" | awk '{print $2}')
      disconnect_device "$selected_mac"
      ;;
    *"type 1 (EV_KEY), code 304 (BTN_SOUTH), value 1"*) # A Button
      selected_mac=$(echo "$devices" | sed -n "$((selected_index + 1))p" | awk '{print $2}')
      connect_device "$selected_mac"
      ;;
    *"type 1 (EV_KEY), code 305 (BTN_EAST), value 1"*) # B Button
      echo "Exiting..."
      pkill -P $$
      break
      ;;
    *)
      continue
      ;;
    esac

    print_devices
  done
}

main
