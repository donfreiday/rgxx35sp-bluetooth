#!/bin/sh

get_default_sink_number() {
  wpctl status | grep -A 5 Sinks | grep '\*' | sed 's/ \|.*\*   //' | cut -f1 -d'.'
}

get_sinks() {
  pw-dump | jq -r '.[] | select(.type == "PipeWire:Interface:Node") | select(.info.props["media.class"] == "Audio/Sink") | "\(.id):\(.info.props["node.description"])"'
}

print_sinks() {
  default_sink=$1
  clear
  echo "Select audio output sink"
  echo "$sinks" | while IFS=: read -r sink_id sink_desc; do
    if [ "$sink_id" = "$default_sink" ]; then
      echo "* $sink_desc"
    else
      echo "  $sink_desc"
    fi
  done
}

main() {
  sinks=$(get_sinks)
  sinks_list=$(echo "$sinks" | cut -d':' -f1 | tr '\n' ' ')
  default_sink=$(get_default_sink_number)

  selected_index=0
  index=0
  for sink_id in $sinks_list; do
    if [ "$sink_id" = "$default_sink" ]; then
      selected_index=$index
      break
    fi
    index=$((index + 1))
  done

  print_sinks "$default_sink"

  evtest /dev/input/event1 | while read -r line; do
    case "$line" in
    *"type 3 (EV_ABS), code 17 (ABS_HAT0Y), value -1"*) # Up
      selected_index=$((selected_index - 1))
      if [ "$selected_index" -lt 0 ]; then
        selected_index=$(echo "$sinks_list" | wc -w)
        selected_index=$((selected_index - 1))
      fi
      ;;
    *"type 3 (EV_ABS), code 17 (ABS_HAT0Y), value 1"*) # Down
      selected_index=$((selected_index + 1))
      if [ "$selected_index" -ge "$(echo "$sinks_list" | wc -w)" ]; then
        selected_index=0
      fi
      ;;
    *"type 1 (EV_KEY), code 304 (BTN_SOUTH), value 1"*) # A Button
      # handle A
      ;;
    *"type 1 (EV_KEY), code 305 (BTN_EAST), value 1"*) # B Button
      echo "Exiting..."
      break
      ;;
    *)
      continue
      ;;
    esac

    new_sink=$(echo "$sinks_list" | awk -v idx="$((selected_index + 1))" '{print $idx}')
    wpctl set-default "$new_sink"
    print_sinks "$new_sink"
  done
}

main
