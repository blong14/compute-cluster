### Nodes

### Local controller setup
1. Add ssh keys to github.com
https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
10. `./bin/controller.sh`
11. `./bin/k3s.sh`

Also, see [Advanced Setup](https://rancher.com/docs/k3s/latest/en/advanced/)

### Services

1. kubectl dashboard: `kubectl proxy`
2. cockroachdb dashboard: `./cluster run proxy -r "svc/cockroachdb-public" -p "8080"`

### Tools
1. cockroach db client connection: `./cluster run connect -d postgres`
2. cockroachdb client proxy: `./cluster run proxy -p "9000:26257" -r "pod/cockroachdb-0"`
