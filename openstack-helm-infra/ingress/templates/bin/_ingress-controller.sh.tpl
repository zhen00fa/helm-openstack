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

set -ex
COMMAND="${@:-start}"

function start () {
  rm -fv /tmp/prometheus-nginx.socket
  exec /usr/bin/dumb-init \
      /nginx-ingress-controller \
      {{- if eq .Values.deployment.mode "namespace" }}
      --watch-namespace ${POD_NAMESPACE} \
      {{- end }}
      --http-port=${PORT_HTTP} \
      --https-port=${PORT_HTTPS} \
      --healthz-port=${PORT_HEALTHZ} \
      --status-port=${PORT_STATUS} \
      --default-server-port=${DEFAULT_SERVER_PORT} \
      --election-id=${RELEASE_NAME} \
      --ingress-class=${INGRESS_CLASS} \
      --default-backend-service=${POD_NAMESPACE}/${ERROR_PAGE_SERVICE} \
      --configmap=${POD_NAMESPACE}/ingress-conf \
      --tcp-services-configmap=${POD_NAMESPACE}/ingress-services-tcp \
      --udp-services-configmap=${POD_NAMESPACE}/ingress-services-udp
}

function stop () {
  kill -TERM 1
}

$COMMAND
