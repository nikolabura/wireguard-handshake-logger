#!/bin/bash

runcmd="bpftrace"
if ! command -v bpftrace &> /dev/null
then
    echo "bpftrace not on path. trying ./bpftrace"
    runcmd="./bpftrace"
fi

seen_pubkeys=""

IFS=$'\n'
while read line
do
    if echo "$line" | grep -q "Attaching"; then
        echo "Starting Wireguard handshake logger."
        continue
    fi
    IFS=$' '
    arr=($line)
    pubkey=$(echo ${arr[-1]} | xxd -r -p | base64)
    left_part=$(echo -n "$line" | sed "s/Pubkey.*//")
    if [[ "$seen_pubkeys" == *"$pubkey"* ]]; then
	    # pubkey has already been seen, use cached API
	    :
    else
	    # pubkey wasn't seen before, hit up the API
	    seen_pubkeys+=" $pubkey"
	    api_devices=$(curl -s $(cat firezone_url.txt)/v0/devices -H 'Content-Type: application/json' -H "Authorization: Bearer $(cat token.txt)")
	    api_users=$(curl   -s $(cat firezone_url.txt)/v0/users   -H 'Content-Type: application/json' -H "Authorization: Bearer $(cat token.txt)")
    fi
    # which device is this?
    device_json=$(echo "$api_devices" | jq ".data[] | select(.public_key==\"$pubkey\")")
    device_name=$(echo "$device_json" | jq -r ".name")
    user_id=$(echo "$device_json" | jq -r ".user_id")
    user_email=$(echo "$api_users" | jq -r ".data[] | select(.id==\"$user_id\") | .email")
    if [ -z "${device_name}" ]; then
	    user_email="UNKNOWN"
	    device_name="UNKNOWN"
    fi
    echo "$left_part Pubkey: $pubkey       Email: $user_email      Device: $device_name"
done < <($runcmd kprobe_wg_handshake.bt)

echo Exiting Wireguard handshake logger.
