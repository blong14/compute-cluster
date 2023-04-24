.PHONY: debug-node update-node upgrade-node

debug-node:
	ansible-playbook build/playbooks/node/temp.yml -u pi --become -K -vv

update-node:
	ansible-playbook build/playbooks/node/update.yml -u pi --become -K -vv

upgrade-node:
	ansible-playbook build/playbooks/node/upgrade-release.yml -f 1 -u pi --become -K -vv

upgrade-k3s:
	ansible-playbook build/playbooks/node/upgrade-k3s.yml -u pi --become -K -vv