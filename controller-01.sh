curl -sfL https://get.k3s.io | sh -s server --cluster-init --token $(cat node-token) --bind-address 0.0.0.0
