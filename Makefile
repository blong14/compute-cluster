include $(wildcard build/playbooks/*/build.mk)

SRC =

.PHONY: build clean

build:
	ansible-playbook build/playbooks/${SRC}/build.yml -f 1 -u pi --become -K -vv

clean:
	ansible-playbook build/playbooks/${SRC}/clean.yml -f 1 -u pi --become -K -vv
