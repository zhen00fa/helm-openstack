#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

#NOTE: Lint and package chart
make fluentd

if [ ! -d "/var/log/journal" ]; then
tee /tmp/fluentd.yaml << EOF
monitoring:
  prometheus:
    enabled: true
pod:
  replicas:
    fluentd: 1
  mounts:
    fluentbit:
      fluentbit:
        volumes:
          - name: runlog
            hostPath:
              path: /run/log
        volumeMounts:
          - name: runlog
            mountPath: /run/log
EOF
helm upgrade --install fluentd ./fluentd \
    --namespace=osh-infra \
    --values=/tmp/fluentd.yaml
else
helm upgrade --install fluentd ./fluentd \
    --namespace=osh-infra \
    --set pod.replicas.fluentd=1 \
    --set monitoring.prometheus.enabled=true
fi

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh osh-infra

#NOTE: Validate Deployment info
helm status fluentd
