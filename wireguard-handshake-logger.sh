#!/bin/bash

runcmd="bpftrace"
if ! command -v bpftrace &> /dev/null
then
    echo "bpftrace not on path. trying ./bpftrace"
    runcmd="./bpftrace"
fi

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
    echo -n "$line" | sed "s/Pubkey.*//"
    echo Pubkey: $pubkey
done < <($runcmd kprobe_wg_handshake.bt)

echo Exiting Wireguard handshake logger.
