.PHONY: build-scrutiny, build-scrutiny-caddy, build-scrutiny-varnish, build-scrutiny-nginx, build-scrutiny-scrape, clean

build-scrutiny:
	ansible-playbook build/playbooks/scrutiny/build.yml -f 1 -u pi --become -K -vv

build-scrutiny-caddy:
	ansible-playbook build/playbooks/scrutiny/build-caddy.yml -f 1 -u pi -vv

build-scrutiny-varnish:
	ansible-playbook build/playbooks/scrutiny/build-varnish.yml -f 1 -u pi -vv

build-scrutiny-nginx:
	ansible-playbook build/playbooks/scrutiny/build-nginx.yml -f 1 -u pi --become -K -vv

build-scrutiny-scrape:
	ansible-playbook build/playbooks/scrutiny/build-scrape.yml -f 1 -u pi -vv

clean:
	ansible-playbook build/playbooks/scrutiny/clean.yml
