**diff --git a/roles/build-helm-packages/defaults/main.yml** b/roles/build-helm-packages/defaults/main.yml
index 81c84a3..d0ffb28 100644
--- a/roles/build-helm-packages/defaults/main.yml
+++ b/roles/build-helm-packages/defaults/main.yml
@@ -15,4 +15,5 @@
 version:
   helm: v2.13.1
 url:
-  google_helm_repo: https://storage.googleapis.com/kubernetes-helm
+ # google_helm_repo: https://storage.googleapis.com/kubernetes-helm
+  google_helm_repo: http://localhost
**diff --git a/roles/build-images/defaults/main.yml b/roles/build-images/defaults/main.yml
index 4d9ddb7..056b43c 100644**
--- a/roles/build-images/defaults/main.yml
+++ b/roles/build-images/defaults/main.yml
@@ -27,6 +27,9 @@ images:
     kubeadm_aio: openstackhelm/kubeadm-aio:dev
 
 url:
-  google_kubernetes_repo: https://storage.googleapis.com/kubernetes-release/release/{{ version.kubernetes }}/bin/linux/amd64
-  google_helm_repo: https://storage.googleapis.com/kubernetes-helm
-  cni_repo: https://github.com/containernetworking/plugins/releases/download/{{ version.cni }}
+  #google_kubernetes_repo: https://storage.googleapis.com/kubernetes-release/release/{{ version.kubernetes }}/bin/linux/amd64
+  #google_helm_repo: https://storage.googleapis.com/kubernetes-helm
+  #cni_repo: https://github.com/containernetworking/plugins/releases/download/{{ version.cni }}
+  google_kubernetes_repo: http://172.17.0.1
+  google_helm_repo: http://172.17.0.1
+  cni_repo: http://172.17.0.1
**diff** --git a/roles/build-images/tasks/kubeadm-aio.yaml b/roles/build-images/tasks/kubeadm-aio.yaml
index f6e3e37..f4d27e9 100644
--- a/roles/build-images/tasks/kubeadm-aio.yaml
+++ b/roles/build-images/tasks/kubeadm-aio.yaml
@@ -44,7 +44,7 @@
       when: proxy.http
       shell: |-
               set -e
-              docker build \
+              docker build --no-cache \
                 --network host \
                 --force-rm \
                 --tag "{{ images.kubernetes.kubeadm_aio }}" \
**diff** --git a/tools/gate/devel/start.sh b/tools/gate/devel/start.sh
index aa6e9ed..1cde97a 100755
--- a/tools/gate/devel/start.sh
+++ b/tools/gate/devel/start.sh
@@ -95,7 +95,7 @@ function dump_logs () {
   set +e
   rm -rf ${LOGS_DIR} || true
   mkdir -p ${LOGS_DIR}/ara
-  ara generate html ${LOGS_DIR}/ara
+  #ara generate html ${LOGS_DIR}/ara
   exit $1
 }
 trap 'dump_logs "$?"' ERR
**diff** --git a/tools/images/kubeadm-aio/Dockerfile b/tools/images/kubeadm-aio/Dockerfile
index 563e257..1e79b99 100644
--- a/tools/images/kubeadm-aio/Dockerfile
+++ b/tools/images/kubeadm-aio/Dockerfile
@@ -75,14 +75,14 @@ RUN set -ex ;\
         jq \
         python-pip \
         gawk ;\
-    pip --no-cache-dir install --upgrade pip==18.1 ;\
+    pip --no-cache-dir install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip==18.1 ;\
     hash -r ;\
-    pip --no-cache-dir install --upgrade setuptools ;\
+    pip --no-cache-dir install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade setuptools ;\
     # NOTE(srwilkers): Pinning ansible to 2.5.5, as pip installs 2.6 by default.
     # 2.6 introduces a new command flag (init) for the docker_container module
     # that is incompatible with what we have currently. 2.5.5 ensures we match
     # what's deployed in the gates
-    pip --no-cache-dir install --upgrade \
+    pip --no-cache-dir install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade \
       requests \
       kubernetes \
       "ansible==2.5.5" ;\
**diff** --git a/tools/images/kubeadm-aio/assets/entrypoint.sh b/tools/images/kubeadm-aio/assets/entrypoint.sh
index 05561f3..076e4e6 100755
--- a/tools/images/kubeadm-aio/assets/entrypoint.sh
+++ b/tools/images/kubeadm-aio/assets/entrypoint.sh
@@ -38,9 +38,9 @@ fi
 : ${NET_SUPPORT_LINUXBRIDGE:="true"}
 : ${PVC_SUPPORT_CEPH:="false"}
 : ${PVC_SUPPORT_NFS:="false"}
-: ${HELM_TILLER_IMAGE:="gcr.io/kubernetes-helm/tiller:${HELM_VERSION}"}
+: ${HELM_TILLER_IMAGE:="ljc359120730/tiller:${HELM_VERSION}"}
 : ${KUBE_VERSION:="${KUBE_VERSION}"}
-: ${KUBE_IMAGE_REPO:="gcr.io/google_containers"}
+: ${KUBE_IMAGE_REPO:="zhaowenlei"}
 : ${KUBE_API_BIND_PORT:="6443"}
 : ${KUBE_NET_DNS_DOMAIN:="cluster.local"}
 : ${KUBE_NET_POD_SUBNET:="192.168.0.0/16"}
**diff** --git a/tools/images/kubeadm-aio/assets/opt/playbooks/roles/deploy-kubelet/templates/10-kubeadm.conf.j2 b/tools/images/kubeadm-aio/assets/opt/playbooks/roles/deploy-kubelet/templates/10-kubeadm.conf.j2
index 926040b..74e917e 100644
--- a/tools/images/kubeadm-aio/assets/opt/playbooks/roles/deploy-kubelet/templates/10-kubeadm.conf.j2
+++ b/tools/images/kubeadm-aio/assets/opt/playbooks/roles/deploy-kubelet/templates/10-kubeadm.conf.j2
@@ -6,7 +6,8 @@ Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain={{ k8s.n
 Environment="KUBELET_AUTHZ_ARGS=--anonymous-auth=false --authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
 Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
 Environment="KUBELET_NODE_LABELS=--node-labels {{ kubelet.kubelet_labels }}"
-Environment="KUBELET_EXTRA_ARGS=--max-pods=220 --pods-per-core=0 --feature-gates=MountPropagation=true --feature-gates=PodShareProcessNamespace=true"
+#Environment="KUBELET_EXTRA_ARGS=--max-pods=220 --pods-per-core=0 --feature-gates=MountPropagation=true --feature-gates=PodShareProcessNamespace=true"
+Environment="KUBELET_EXTRA_ARGS=--max-pods=220 --pods-per-core=0 --feature-gates=MountPropagation=true --feature-gates=PodPriority=true"
 #ExecStartPre=-+/sbin/restorecon -v /usr/bin/kubelet #SELinux
 ExecStart=
 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_NODE_LABELS $KUBELET_EXTRA_ARGS
