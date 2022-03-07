echo $(cat node-token)
curl -sfL https://get.k3s.io | K3S_TOKEN=$(cat node-token) sh -s server --server https://controller-01.local:6443
