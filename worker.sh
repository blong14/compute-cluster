#!/bin/bash


K3S_URL=$(cat etc/controller-ip.conf | awk '{print $2}')
K3S_TOKEN=$(cat etc/network.conf)


curl -sfL https://get.k3s.io | sh -

