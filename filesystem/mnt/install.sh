#!/usr/bin/env bash
: "${SSH_AUTHORIZED_KEYS?}"

apt-get update
apt-get install -y vim htop curl wget openssh-server

ssh-keygen -t rsa -b 4096 -q -N ""
echo $SSH_AUTHORIZED_KEYS > ~/.ssh/authorized_keys

sh /mnt/setup-ca.sh
