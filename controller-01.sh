curl -sfL https://get.k3s.io | sh -s server --cluster-init --token $(cat /etc/node-token) --bind-address 0.0.0.0
