#!/bin/sh

sysctl -w net.ipv6.conf.all.forwarding=1 || exit 1

yggdrasil -useconffile /etc/yggdrasil.conf
