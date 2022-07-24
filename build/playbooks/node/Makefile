.PHONY: build clean update

build:
	ansible-playbook build/playbooks/node/build.yml -u pi --become -K -vv

clean:
	ansible-playbook build/playbooks/node/clean.yml -u pi --become -K -vv

update:
	ansible-playbook build/playbooks/node/update.yml -u pi --become -K -vv

debug:
	ansible-playbook build/playbooks/node/temp.yml -u pi --become -K -vv

