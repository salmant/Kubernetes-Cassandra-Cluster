#!/bin/bash

# Giving the Cassandra container some time to be added as a new Pod to the Cassandra Cluster before executing the DNS query.
sleep 10

current_Pod_ip=$(hostname --ip-address)

CASSANDRA_SEEDS=$(nslookup cassandra-headless-service | grep -v $current_Pod_ip | sort | awk '/^Address: / { print $2 }' | xargs | sed -e 's/ /,/g')

export CASSANDRA_SEEDS

/docker-entrypoint.sh "$@"
