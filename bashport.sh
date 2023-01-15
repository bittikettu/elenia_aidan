#!/bin/bash
. ./credentials

timestamp=$(mktemp)
#echo $username
#echo $password

function toWapice {
  #echo $username
  #echo 1 $1
  #echo 2 $2
  #echo 3 $3
  #echo 4 $4
  #echo 5 $5
  #data="[{\"name\": \"$1\",\"path\": \"Mariankatu5/electricity\",\"v\": val,\"ts\": $3,\"unit\": \"sdf\"}]"
  data="[{\"name\": \"$1-2\",\"path\": \"Consumption\",\"v\": $2,\"unit\": \"$4\",\"dataType\":\"double\", \"ts\": $3000}]"
  #data="{\"name\": \"$1\",\"path\": \"Consumption\",\"v\": $2,\"unit\": \"$4\"}"
  echo  $data
  curl -X POST --user $username:$password -H "Content-Type:application/json" -d "$data" "https://my.iot-ticket.com/api/v1/process/write/$deviceid/"
}

function conv2JSON {
  #echo $1
  path=$(echo -n $1| cut -d "(" -f 1)
  units=$(echo -n $1| cut -d "*" -f 2|sed 's/)//')|tr '\n' ' '
  pre_value=$(echo -n $1| cut -d "(" -f 2|sed 's/)//')
  value=$(awk -v v="${pre_value}" 'BEGIN{print v+0}')
  datetime=$(cat $timestamp|sed -E "s|([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}).+|\2/\3/20\1 \4:\5:\6|")
  echo $datetime
  epoch=$(date -d "$datetime + 3 hours" +"%s")
  toWapice $path $value $epoch $units
  #echo "{\"ts\":$epoch,\"val\":$value}"
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
    #*)
    #  conv2JSON $line current
    #;;
    "1-0:1.7.0"*)
      #(
      conv2JSON $line current
      #)&
      #toWapice $value
      #mosquitto_pub -r -t aidan/wats -m "${value}" &
    ;;
    "1-0:1.8.0"*)
      conv2JSON $line total
      #mosquitto_pub -r -t aidan/total -m "${value}" &
    ;;
    esac
fi
done < "$input"

