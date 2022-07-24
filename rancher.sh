helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

helm install rancher rancher-latest/rancher \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  --namespace cattle-system \
  --set hostname=compute.cluster \
  --set replicas=1
