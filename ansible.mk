server-ping:
	ansible all -m ping -u pi --inventory=etc/ansible/hosts

reboot:
	ansible all -a "/sbin/reboot" -f 1 -u pi --become -K --inventory=etc/ansible/hosts

update:
	ansible-playbook playbooks/cluster/update.yml -f 1 -u pi --become -K -vv --inventory=etc/ansible/hosts

# TODO(Ben): probably could do some ansible magic here to reduce the number
# "build-*" commands; I don't currently know how to do that and its easier
# at this point to just copy/paste!
build-cockroachdb:
	ansible-playbook playbooks/cockroach/build.yml -f 1 -u pi -vv

build-graphapp:
	ansible-playbook playbooks/graftapp/graphapp_build.yml -f 1 -u pi -vv

build-cluster:
	ansible-playbook playbooks/cluster/build.yml -f 1 -u pi -vv

build-ncluster:
	ansible-playbook playbooks/ncluster/build.yml -f 1 -u pi -vv

build-scrutiny:
	ansible-playbook playbooks/scrutiny/build.yml -f 1 -u pi -vv

build-scrutiny-caddy:
	ansible-playbook playbooks/scrutiny/build-caddy.yml -f 1 -u pi -vv

build-scrutiny-varnish:
	ansible-playbook playbooks/scrutiny/build-varnish.yml -f 1 -u pi -vv

build-scrutiny-nginx:
	ansible-playbook playbooks/scrutiny/build-nginx.yml -f 1 -u pi -vv

build-scrutiny-scrape:
	ansible-playbook playbooks/scrutiny/build-scrape.yml -f 1 -u pi -vv

deploy-graphapp: build-graphapp
	helm upgrade --install graphapp charts/graphapp

deploy-scrutiny: build-scrutiny
	helm upgrade --install scrutiny charts/scrutiny

deploy-scrutiny-caddy: build-scrutiny-caddy
	helm upgrade --install scrutiny-caddy charts/caddy

deploy-scrutiny-varnish: build-scrutiny-varnish
	helm upgrade --install scrutiny-varnish charts/varnish

deploy-scrutiny-nginx: build-scrutiny-nginx
	helm upgrade --install scrutiny-nginx charts/nginx

deploy-scrutiny-scrape: build-scrutiny-scrape
	helm upgrade --install scrutiny-scrape charts/scrape
