#!/bin/bash

# sudo apt update && apt install -y openssh-server net-tools  

# install k3s
curl -sfL https://get.k3s.io | sh -


# install helm
mkdir -p ~/.config/helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh

cp charts/repositories.yaml ~/.config/helm
cp charts/repositories.lock ~/.config/helm

