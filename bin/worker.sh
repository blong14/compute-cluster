#!/bin/bash

sudo apt update
sudo apt install -y curl git vim rcm openssh-server net-tools  

K3S_URL=192.168.1.206
K3S_TOKEN=K10a69ee48a4bb0b10136030a69ad227617e38a7243c1e96708ab6c82b8bb4432d0::server:79e683b5f3a98a6c74f822391a64f778

curl -sfL https://get.k3s.io | K3S_URL="https://$K3S_URL:6443" K3S_TOKEN=$K3S_TOKEN sh -

