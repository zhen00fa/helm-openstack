#!/bin/bash

{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -e

# Extract connection details
RABBIT_HOSTNAME=`echo $RABBITMQ_ADMIN_CONNECTION | awk -F'[@]' '{print $2}' \
  | awk -F'[:/]' '{print $1}'`
RABBIT_PORT=`echo $RABBITMQ_ADMIN_CONNECTION | awk -F'[@]' '{print $2}' \
  | awk -F'[:/]' '{print $2}'`

# Extract Admin User creadential
RABBITMQ_ADMIN_USERNAME=`echo $RABBITMQ_ADMIN_CONNECTION | awk -F'[@]' '{print $1}' \
  | awk -F'[//:]' '{print $4}'`
RABBITMQ_ADMIN_PASSWORD=`echo $RABBITMQ_ADMIN_CONNECTION | awk -F'[@]' '{print $1}' \
  | awk -F'[//:]' '{print $5}'`

function rabbit_check_node_count () {
  echo "Checking node count "
  NODES_IN_CLUSTER=$(rabbitmqadmin \
    --host="${RABBIT_HOSTNAME}" \
    --port="${RABBIT_PORT}" \
    --username="${RABBITMQ_ADMIN_USERNAME}" \
    --password="${RABBITMQ_ADMIN_PASSWORD}" \
    list nodes -f bash | wc -w)
  if [ "$NODES_IN_CLUSTER" -eq "$RABBIT_REPLICA_COUNT" ]; then
    echo "Number of nodes in cluster match number of desired pods ($NODES_IN_CLUSTER)"
  else
    echo "Number of nodes in cluster ($NODES_IN_CLUSTER) does not match number of desired pods ($RABBIT_REPLICA_COUNT)"
    exit 1
  fi
}
# Check node count
rabbit_check_node_count

function rabbit_find_partitions () {
  rabbitmqadmin \
    --host="${RABBIT_HOSTNAME}" \
    --port="${RABBIT_PORT}" \
    --username="${RABBITMQ_ADMIN_USERNAME}" \
    --password="${RABBITMQ_ADMIN_PASSWORD}" \
    list nodes -f raw_json | \
  python -c "
import json, sys, traceback
print('Checking cluster partitions')
obj=json.load(sys.stdin)
for num, node in enumerate(obj):
  try:
    partition = node['partitions']
    if partition:
      raise Exception('cluster partition found: %s' % partition)
  except KeyError:
    print('Error: partition key not found for node %s' % node)
    sys.exit(1)
print('No cluster partitions found')
  "
}

rabbit_find_partitions

function rabbit_check_users_match () {
  echo "Checking users match on all nodes"
  NODES=$(rabbitmqadmin \
    --host="${RABBIT_HOSTNAME}" \
    --port="${RABBIT_PORT}" \
    --username="${RABBITMQ_ADMIN_USERNAME}" \
    --password="${RABBITMQ_ADMIN_PASSWORD}" \
    list nodes -f bash)
  USER_LIST=$(mktemp --directory)
  echo "Found the following nodes: ${NODES}"
  for NODE in ${NODES}; do
    echo "Checking Node: ${NODE#*@}"
    rabbitmqadmin \
      --host=${NODE#*@} \
      --port="${RABBIT_PORT}" \
      --username="${RABBITMQ_ADMIN_USERNAME}" \
      --password="${RABBITMQ_ADMIN_PASSWORD}" \
      list users -f bash > ${USER_LIST}/${NODE#*@}
  done
  cd ${USER_LIST}; diff -q --from-file $(ls ${USER_LIST})
  echo "User lists match for all nodes"
}
# Check users match on all nodes
rabbit_check_users_match
