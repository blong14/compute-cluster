.PHONY: build clean deploy-cockroachdb deploy-scrutiny deploy-scrutiny

deploy-scrutiny:
	helm upgrade --install scrutiny deploy/charts/scrutiny/scrutiny
	helm upgrade --install scrutiny-nginx deploy/charts/scrutiny/nginx
	helm upgrade --install scrutiny-caddy deploy/charts/scrutiny/caddy
	helm upgrade --install scrutiny-varnish deploy/charts/scrutiny/varnish
	helm upgrade --install scrutiny-scrape deploy/charts/scrutiny/scrape

build:
	kubectl apply -f deploy/charts/dsnutil
	kubectl apply -f deploy/charts/cockroachdb-operator/crdb.cockroachlabs.com_crdbclusters.yaml
	kubectl apply -f deploy/charts/cockroachdb-operator/operator.yaml
	kubectl apply -f deploy/charts/cockroachdb-operator/cluster.yaml
	kubectl apply -f deploy/charts/cockroachdb-operator/client.yaml
	kubectl apply -f deploy/charts/sqlite3/client.yaml
	helm upgrade --install jaeger deploy/charts/jaeger
	helm upgrade --install ping-db deploy/charts/ping-db

clean:
	kubectl delete -f deploy/charts/dsnutil
	kubectl delete -f deploy/charts/cockroachdb-operator/crdb.cockroachlabs.com_crdbclusters.yaml
	kubectl delete -f deploy/charts/cockroachdb-operator/operator.yaml
	kubectl delete -f deploy/charts/cockroachdb-operator/cluster.yaml
	kubectl delete -f deploy/charts/cockroachdb-operator/client.yaml
	kubectl delete -f deploy/charts/sqlite3/client.yaml
	helm delete jaeger
	helm delete ping-db
