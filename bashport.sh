#!/bin/bash

timestamp=$(mktemp)

function conv2JSON {
  pre_value=$(echo $1| cut -d "(" -f 2|sed 's/)//')
  value=$(awk -v v="${pre_value}" 'BEGIN{print v+0}')
  datetime=$(cat $timestamp|sed -E "s|([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}).+|\3/\2/20\1 \4:\5:\6|")
  epoch=$(date -d "$datetime" +"%s")
  echo "{\"ts\":$epoch,\"val\":$value}"
}

input="/dev/ttyUSB0"
while IFS= read -r line
do
  if [ ${#line} -ge 3 ]; then
    case "${line}" in
    "/ADN9 7534"*)
      echo "start" > /dev/null
    ;;
    "0-0:1.0.0"*)
      ts=$(echo $line| cut -d "(" -f 2|sed 's/)//')
      echo $ts > $timestamp
    ;;
    "!"*)
      echo "end" > /dev/null
    ;;
    "1-0:1.7.0"*)
      value=$(conv2JSON $line)
      mosquitto_pub -r -t aidan/wats -m "${value}"
    ;;
    "1-0:1.8.0"*)
      value=$(conv2JSON $line)
      mosquitto_pub -r -t aidan/total -m "${value}"
    ;;
    esac
fi
done < "$input"

