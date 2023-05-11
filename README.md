# Wireguard Handshake Logger
Logs outgoing Wireguard handshake responses using `bpftrace` kprobes. Outputs the peer public key for each handshake, for use in monitoring multi-peer setups.

**Skip to [Setup](#setup) for instructions.**

## Motivation

On a multi-peer Wireguard server (for example, a company VPN server with one peer per each employee device) one may wish to log all IP addresses that successfully authenticate with the VPN.

Wireguard has built-in debugging facilities, as [detailed here](https://ubuntu.com/server/docs/wireguard-vpn-troubleshooting).
```shell
$ echo "module wireguard +p" | sudo tee /sys/kernel/debug/dynamic_debug/control
$ sudo dmesg | tail -n 10
[6305964.569633] wireguard: wg-firezone: Receiving handshake initiation from peer 18 (93.184.216.34:61795)
[6305964.569642] wireguard: wg-firezone: Sending handshake response to peer 18 (93.184.216.34:61795)
[6305964.569891] wireguard: wg-firezone: Keypair 42365 destroyed for peer 18
[6305964.569893] wireguard: wg-firezone: Keypair 42371 created for peer 18
[6305964.586554] wireguard: wg-firezone: Receiving keepalive packet from peer 18 (93.184.216.34:61795)
[6305983.760595] wireguard: wg-firezone: Receiving handshake initiation from peer 14 (130.85.12.141:54719)
[6305983.760604] wireguard: wg-firezone: Sending handshake response to peer 14 (130.85.12.141:54719)
[6305983.760823] wireguard: wg-firezone: Keypair 42366 destroyed for peer 14
[6305983.760825] wireguard: wg-firezone: Keypair 42372 created for peer 14
[6305983.774605] wireguard: wg-firezone: Receiving keepalive packet from peer 14 (130.85.12.141:54719)
```

While useful, these have a critical flaw in that they don't make it easy to tell who "peer 14" is.
One might think that this is just the index of the peer in the list, but in my experience, this wasn't the case.
Looking at [the source](https://github.com/torvalds/linux/blob/d295b66a7b66ed504a827b58876ad9ea48c0f4a8/drivers/net/wireguard/send.c#L90) seems to indicate that these numbers
come from `peer->internal_id`, which doesn't appear to be exposed anywhere.

## Example

```
$ sudo ./wireguard-handshake-logger.sh 
bpftrace not on path. trying ./bpftrace
Starting Wireguard handshake logger.
Sent handshake response          Interface: wg0       Endpoint IP: 130.85.62.70       Pubkey: uH/67OxEOXOlceh1vnoLB30TJD6Ah2CYojo3mTOy8VI=
Sent handshake response          Interface: wg0       Endpoint IP: 130.85.62.70       Pubkey: uH/67OxEOXOlceh1vnoLB30TJD6Ah2CYojo3mTOy8VI=
Sent handshake response          Interface: wg0       Endpoint IP: 93.184.216.34      Pubkey: K9k7xmU+x0aEsZ0e3ebZDw2pwCzdNAoFSG+Wzwsx/HI=
^C
$
```

## Setup

### Prerequisites

- bpftrace (tested with version v0.13.0, known to not work with version v0.9.4)
- Linux kernel headers (`apt install linux-headers-generic` or such)

The easiest way to install bpftrace is probably by just pulling the binary from their docker image, as specified in their install instructions.
```
docker run -v $(pwd):/output quay.io/iovisor/bpftrace:master-vanilla_llvm_clang_glibc2.23  /bin/bash -c "cp /usr/bin/bpftrace /output"
```

If you do not have `bpftrace` on your path, but you do have it in the same folder as the script, it'll run it.

### Running

```
git clone https://github.com/nikolabura/wireguard-handshake-logger
cd wireguard-handshake-logger
./wget-wireguard-headers.sh     # uses wget to download wireguard header files into a wireguard/ folder
# make sure you either have bpftrace installed or a ./bpftrace binary in the same folder
sudo ./wireguard-handshake-logger.sh
```

Ctrl+C the program when you're done.
