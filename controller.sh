#!/bin/bash

curl -sfL https://get.k3s.io | sh -

mkdir -R ~/.config/helm
cp charts/repositories.yaml ~/.config/helm
cp charts/repositories.lock ~/.config/helm
