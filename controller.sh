#!/bin/bash

sudo apt update && apt install -y openssh-server net-tools  

# install k3s
curl -sfL https://get.k3s.io | sh -


# install helm
mkdir ~/.config/helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh

cp charts/repositories.yaml ~/.config/helm
cp charts/repositories.lock ~/.config/helm

# configure helm and kubectl
sudo cp /etc/rancher/k3s/k3s.yaml etc/rancher/k3s/k3s.yaml
sudo chown pi:pi etc/rancher/k3s/k3s.yaml
cp etc/.bash_profile ~/.bash_profile
source ~/.bash_profile
