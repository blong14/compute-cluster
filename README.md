## Compute Cluster (WIP)
An attempt at a personal multi-node computing environment. Built on top of k3s and raspberry-pi.

### Features (so far)
1. prometheus monitoring stack
2. cockroachdb cluster
3. apache beam
4. cli tool to manage cluster workloads (jobs, services, etc)

### Nodes

![IMG_0164](https://user-images.githubusercontent.com/3110701/121784141-42172e80-cb80-11eb-94a8-372053343e88.jpg)

### Local controller setup (probably missing steps and not correct order)
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
12. `helm upgrade --install init-db charts/init-db`

### Node setup
1. `./bin/worker.sh`

### Services

1. kubectl dashboard: `kubectl proxy`
2. cockroachdb dashboard: `./cluster run proxy -r "svc/cockroachdb-public" -p "8080"`
3. grafana proxy: `./cluster run proxy -p "3000:80" -r "svc/prometheus-grafana"`

### Tools
1. cockroach db client connection: `./cluster run connect -d postgres`
2. cockroachdb client proxy: `./cluster run proxy -p "9000:26257" -r "pod/cockroachdb-0"`
