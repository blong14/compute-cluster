server-ping:
	ansible all -m ping -u pi --inventory=etc/ansible/hosts

reboot:
	ansible all -a "/sbin/reboot" -f 1 -u pi --become -K --inventory=etc/ansible/hosts

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

deploy-graphapp: build-graphapp
	helm upgrade --install graphapp charts/graphapp

