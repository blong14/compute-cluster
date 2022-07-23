echo $(cat node-token)
curl -sfL https://get.k3s.io | K3S_TOKEN=$(cat node-token) sh -s server --server https://compute.cluster:6443 --bind-address 0.0.0.0
