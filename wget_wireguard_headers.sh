#!/bin/bash

mkdir wireguard
cd wireguard

for filename in allowedips.h cookie.h device.h messages.h noise.h peer.h peerlookup.h; do
    echo Getting $filename...
    wget https://raw.githubusercontent.com/torvalds/linux/master/drivers/net/wireguard/$filename
done
