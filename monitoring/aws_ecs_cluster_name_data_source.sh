#!/bin/bash

set -e

eval "$(jq -r '@sh "needle=\(.needle)"')"

# Get the cluster ARN containing the needle and grab the last bit after "cluster/"
cluster_name="$(aws ecs list-clusters \
    | jq -r ".clusterArns[] | select(contains(\"$needle\"))" \
    | sed 's/.*cluster\///')"

echo "{\"cluster_name\": \"$cluster_name\"}"
