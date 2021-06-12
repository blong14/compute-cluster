## Compute Cluster (WIP)


### Nodes

![IMG_0164](https://user-images.githubusercontent.com/3110701/121784141-42172e80-cb80-11eb-94a8-372053343e88.jpg)


### Local controller setup (probably missing steps and not correct order)
1. Add ssh keys to github.com
https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
2. mkdir Developer
3. git clone dotfiles
4. apt install vim
5. apt install rcup
6. rcup
7. cd Developer
8. git clone compute-cluster
9. helm upgrade --install init-db charts/init-db

### Services

1. kubectl dashboard: `kubectl proxy`
2. cockroachdb dashboard: `kubectl port-forward svc/cockroachdb-public 8080`
3. grafana: `kubectl port-forward svc/prometheus-grafana 3000:80`

