#!/usr/bin/env bash

apt-get update
apt-get install -y vim htop curl wget openssh-server

chmod 700 ~/.ssh

sh /mnt/setup-ca.sh
