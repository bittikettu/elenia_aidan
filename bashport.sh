#!/bin/bash

function convtofloat {
  pre_value=$(echo $1| cut -d "(" -f 2|sed 's/)//')
  deps=$(awk -v v="${pre_value}" 'BEGIN{print v+0}')
  aika=$(cat ./aika)
  echo $aika,$deps
}

input="/dev/ttyUSB0"
while IFS= read -r line
do
if [ ${#line} -ge 3 ]; then
  case "${line}" in
  "/ADN9 7534"*)
  echo "start"
  ;;
  "0-0:1.0.0"*)
  ts=$(echo $line| cut -d "(" -f 2|sed 's/)//')
  echo $ts > aika
  ;;
  "!"*)
  echo "end"
  ;;
  "1-0:1.7.0"*)
  aika=$(cat ./aika)
  value=$(convtofloat $line)
  mosquitto_pub -r -t wattage -m "${value}"
  ;;
  "1-0:1.8.0"*)
  value=$(convtofloat $line)
  mosquitto_pub -r -t total -m "${value}"
  ;;
  esac
fi
done < "$input"

