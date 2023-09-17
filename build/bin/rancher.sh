helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

helm install rancher rancher-stable/rancher \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  --namespace cattle-system \
  --set hostname=compute.cluster \
  --set replicas=1
