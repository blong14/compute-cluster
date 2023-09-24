.PHONY: debug-node upgrade-node

debug-node:
	ansible-playbook build/playbooks/node/temp.yml -u pi --become -K -vv

upgrade-node:
	ansible-playbook build/playbooks/node/upgrade-release.yml -f 1 -u pi --become -K -vv
