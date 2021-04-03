#!/bin/bash

sudo apt update && apt install -y openssh-server net-tools  

K3S_URL=$(cat etc/controller-ip.conf | awk '{print $2}')
K3S_TOKEN=$(cat etc/network.conf)

curl -sfL https://get.k3s.io | K3S_URL="https://$K3S_URL:6443" K3S_TOKEN=$K3S_TOKEN sh -

# configure kubectl
mkdir -p etc/rancher/k3s
sudo cp /etc/rancher/k3s/k3s.yaml etc/rancher/k3s/k3s.yaml
sudo chown pi:pi etc/rancher/k3s/k3s.yaml
cp etc/.bash_profile ~/.bash_profile
source ~/.bash_profile
