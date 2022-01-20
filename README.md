## Compute Cluster (WIP)
An attempt at a personal multi-node computing environment. Built on top of k3s and raspberry-pi.

### Features (so far)
1. prometheus monitoring stack
2. cockroachdb cluster
3. apache beam
4. cli tool to manage cluster workloads (jobs, services, etc)

### Nodes

![IMG_0164](https://user-images.githubusercontent.com/3110701/121784141-42172e80-cb80-11eb-94a8-372053343e88.jpg)

### Local controller setup (probably missing steps and not correct order; also specific to my setup Pop!_OS 21.04)
1. Add ssh keys to github.com
https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
2. `mkdir Developer`
3. `git clone dotfiles`
4. `apt install vim`
5. `apt install rcup`
6. `rcup`
7. `cd Developer`
8. `git clone compute-cluster`
9. `cd compute-cluster`
10. `./bin/controller.sh`
11. `./bin/k3s.sh`
12. `kubectl apply -f charts/dnsutil`
13. `kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/config/crd/bases/crdb.cockroachlabs.com_crdbclusters.yaml`
14. `kubectl apply -f charts/cockroachdb-operator/operator.yaml`
15. `kubectl apply -f charts/cockroachdb-operator/cluster.yaml`
16. `kubectl apply -f charts/cockroachdb-operator/client.yaml`
17. `helm install ping-db charts/ping-db`
18. `helm install prometheus prometheus-community/kube-prometheus-stack` (u admin p prom-operator)

### Node setup (Ubuntu 21.04)
1. `sudo ufw disable`
2. `sudo cp etc/10-flannel.link /etc/systemd/network/`
3. `./bin/worker.sh`

### Node setup (Ubuntu 21.10)
1. `sudo apt install linux-modules-extra-raspi`
2. `reboot`

Also, see [Advanced Setup](https://rancher.com/docs/k3s/latest/en/advanced/)

### Services

1. kubectl dashboard: `kubectl proxy`
2. cockroachdb dashboard: `./cluster run proxy -r "svc/cockroachdb-public" -p "8080"`
3. grafana proxy: `./cluster run proxy -p "3000:80" -r "svc/prometheus-grafana"`

### Tools
1. cockroach db client connection: `./cluster run connect -d postgres`
2. cockroachdb client proxy: `./cluster run proxy -p "9000:26257" -r "pod/cockroachdb-0"`
