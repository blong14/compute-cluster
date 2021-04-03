#!/bin/bash

# configure helm and kubectl
mkdir -p etc/rancher/k3s
sudo cp /etc/rancher/k3s/k3s.yaml etc/rancher/k3s/k3s.yaml
sudo chown pi:pi etc/rancher/k3s/k3s.yaml

cp etc/.bash_profile ~/.bash_profile
source ~/.bash_profile

