export INSTALL_K3S_VERSION=v1.31.4+k3s1
curl -sfL https://get.k3s.io | K3S_TOKEN=$(cat /etc/node-token) K3S_URL=https://compute.cluster:6443 sh -s
