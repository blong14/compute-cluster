set -x

echo "$1"

kubectl run --rm -it cockroachdb-client --image=marceloglezer/cockroach:v20.1.7 --overrides='{"apiVersion":"v1","spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchFields":[{"key":"metadata.name","operator":"In","values":["worker-01"]}]}]}}}}}' --command -- /cockroach/cockroach sql --insecure --host=cockroachdb-1.cockroachdb.default.svc.cluster.local --database=$1
