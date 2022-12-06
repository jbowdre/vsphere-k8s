#!/bin/bash -eu
source ./env.txt

if [ ! -f /etc/kubernetes/manifests/kube-vip.yaml ]; then
  echo ">> Configuring kube-vip..."
  sudo ctr image pull ghcr.io/kube-vip/kube-vip:"${KUBEVIP_VER}"
  sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:"${KUBEVIP_VER}" vip /kube-vip manifest pod \
    --interface ens192 \
    --vip "${K8S_CONTROLPLANE_VIP}" \
    --controlplane \
    --arp \
    --leaderElection | sudo tee /etc/kubernetes/manifests/kube-vip.yaml
fi

if [ "${HOSTNAME}" == "${K8S_INITIAL_NODE}" ]; then
  if ! kubectl get nodes 2>/dev/null; then
    echo ">> Bootstrapping first controlplane node..."
    cat << EOF > kubeadminit.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: ${KUBEADM_TOKEN}
  ttl: 0s
  usages:
  - signing
  - authentication
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: "external"
certificateKey: ${KUBEADM_CERTKEY}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: ${K8S_VER}
controlPlaneEndpoint: ${K8S_CONTROLPLANE_VIP}
clusterName: ${K8S_CLUSTER_NAME}
networking:
  dnsDomain: cluster.local
  serviceSubnet: ${K8S_SERVICE_CIDR}
  podSubnet: ${K8S_POD_CIDR}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
EOF
    if sudo kubeadm init --upload-certs --config kubeadminit.yaml; then
      echo ">> Node ${HOSTNAME} successfully initialized!"
      touch .k8s-node-success
      mkdir -p "${HOME}"/.kube
      sudo cp -i /etc/kubernetes/admin.conf "${HOME}"/.kube/config
      sudo chown "$(id -u):$(id -g)" "${HOME}"/.kube/config

      echo ">> Applying Calico networking..."
      kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

      echo ">> Creating discovery config..."
      kubectl -n kube-public get configmap cluster-info -o jsonpath='{.data.kubeconfig}' > discovery.yaml
      sudo install -o root -g root -m 600 discovery.yaml /etc/kubernetes/discovery.yaml
    else
      echo ">> [ERROR] Cluster initialization unsuccessful on ${HOSTNAME}! <<"
      exit 1
    fi
  fi
  echo ">> Waiting up to 15 minutes for all nodes to be Ready..."
  attempts_max=90
  attempt=0
  until [ "$(kubectl get nodes | grep -c ' Ready ')" == "${K8S_NODE_COUNT}" ]; do
    if [ ${attempt} -eq ${attempts_max} ]; then
      echo ">> [ERROR] Timeout waiting for cluster online! <<"
      exit 1
    fi
    attempt=$((attempt+1))
    sleep 10
  done
  echo ">> Continuing after $((attempt*10)) seconds."
  echo ">> Configuring vSphere Cloud Provider Interface..."
  cat << EOF | kubectl apply -f -
# https://raw.githubusercontent.com/kubernetes/cloud-provider-vsphere/release-1.25/releases/v1.25/vsphere-cloud-controller-manager.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  labels:
    vsphere-cpi-infra: service-account
    component: cloud-controller-manager
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: vsphere-cloud-secret
  labels:
    vsphere-cpi-infra: secret
    component: cloud-controller-manager
  namespace: kube-system
stringData:
  ${VCENTER_SERVER}.username: ${VCENTER_USERNAME}
  ${VCENTER_SERVER}.password: ${VCENTER_PASSWORD}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vsphere-cloud-config
  labels:
    vsphere-cpi-infra: config
    component: cloud-controller-manager
  namespace: kube-system
data:
  vsphere.conf: |
    global:
      port: 443
      insecureFlag: true
      secretName: vsphere-cloud-secret
      secretNamespace: kube-system
    vcenter:
      ${VCENTER_SERVER}:
        server: ${VCENTER_SERVER}
        datacenters:
          - ${VCENTER_DATACENTER}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: servicecatalog.k8s.io:apiserver-authentication-reader
  labels:
    vsphere-cpi-infra: role-binding
    component: cloud-controller-manager
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
  - apiGroup: ""
    kind: ServiceAccount
    name: cloud-controller-manager
    namespace: kube-system
  - apiGroup: ""
    kind: User
    name: cloud-controller-manager
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:cloud-controller-manager
  labels:
    vsphere-cpi-infra: cluster-role-binding
    component: cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:cloud-controller-manager
subjects:
  - kind: ServiceAccount
    name: cloud-controller-manager
    namespace: kube-system
  - kind: User
    name: cloud-controller-manager
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-controller-manager
  labels:
    vsphere-cpi-infra: role
    component: cloud-controller-manager
rules:
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
      - update
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - "*"
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - ""
    resources:
      - services/status
    verbs:
      - patch
  - apiGroups:
      - ""
    resources:
      - serviceaccounts
    verbs:
      - create
      - get
      - list
      - watch
      - update
  - apiGroups:
      - ""
    resources:
      - persistentvolumes
    verbs:
      - get
      - list
      - update
      - watch
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - create
      - get
      - list
      - watch
      - update
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "coordination.k8s.io"
    resources:
      - leases
    verbs:
      - create
      - get
      - list
      - watch
      - update
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vsphere-cloud-controller-manager
  labels:
    component: cloud-controller-manager
    tier: control-plane
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: vsphere-cloud-controller-manager
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: vsphere-cloud-controller-manager
        component: cloud-controller-manager
        tier: control-plane
    spec:
      tolerations:
        - key: node.cloudprovider.kubernetes.io/uninitialized
          value: "true"
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
          operator: Exists
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
          operator: Exists
        - key: node.kubernetes.io/not-ready
          effect: NoSchedule
          operator: Exists
      securityContext:
        runAsUser: 1001
      serviceAccountName: cloud-controller-manager
      priorityClassName: system-node-critical
      containers:
        - name: vsphere-cloud-controller-manager
          image: gcr.io/cloud-provider-vsphere/cpi/release/manager:v1.25.0
          args:
            - --cloud-provider=vsphere
            - --v=2
            - --cloud-config=/etc/cloud/vsphere.conf
          volumeMounts:
            - mountPath: /etc/cloud
              name: vsphere-config-volume
              readOnly: true
          resources:
            requests:
              cpu: 200m
      hostNetwork: true
      volumes:
        - name: vsphere-config-volume
          configMap:
            name: vsphere-cloud-config
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/control-plane
                operator: Exists
            - matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: Exists
EOF
  echo ">> Configuring vSphere Cloud Storage Interface..."
  cat << EOF | kubectl apply -f -
# https://raw.githubusercontent.com/kubernetes-sigs/vsphere-csi-driver/v2.7.0/manifests/vanilla/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: vmware-system-csi
EOF

  cat << EOF > csi-vsphere.conf
[Global]
cluster-id = "${K8S_CLUSTER_NAME}"
# ca-file = <ca file path> # optional, use with insecure-flag set to false
# thumbprint = "<cert thumbprint>" # optional, use with insecure-flag set to false without providing ca-file

[VirtualCenter "${VCENTER_SERVER}"]
insecure-flag = "true"
user = "${VCENTER_USERNAME}"
password = "${VCENTER_PASSWORD}"
port = "443"
datacenters = "${VCENTER_DATACENTER}"
EOF

  kubectl create secret generic vsphere-config-secret --from-file=csi-vsphere.conf --namespace=vmware-system-csi
  wget "https://raw.githubusercontent.com/kubernetes-sigs/vsphere-csi-driver/v2.7.0/manifests/vanilla/vsphere-csi-driver.yaml"
  if [ "${K8S_CONTROLPLANE_COUNT}" -lt 3 ]; then
    sed -i 's/replicas: 3/replicas: 1/' vsphere-csi-driver.yaml
  fi
  if kubectl apply -f vsphere-csi-driver.yaml; then
    echo ">> Cluster initialization complete!"
    touch .k8s-cluster-success
    rm -f csi-vsphere.conf discovery.yaml env.txt kubeadminit.yaml initialize-controlplane.sh vsphere-csi-driver.yaml
  else
    echo ">> [ERROR] Failed to configure CSI! <<"
  fi
else
  echo ">> Waiting up to 5 minutes for initial control node..."
  attempts_max=30
  attempt=0
  until nc "${K8S_CONTROLPLANE_VIP}" 6443 -w 1 2>/dev/null; do
    if [ ${attempt} -eq ${attempts_max} ]; then
      echo ">> [ERROR] Timeout waiting for control node! <<"
      exit 1
    fi
    attempt=$((attempt+1))
    sleep 10
  done
  echo ">> Continuing after $((attempt*10)) seconds."
  echo ">> Joining cluster..."
  attempts_max=6
  attempt=0
  until [ -f /etc/kubernetes/discovery.yaml ]; do
    scp -o StrictHostKeyChecking=no "${K8S_CONTROLPLANE_VIP}":discovery.yaml . 2>/dev/null
    sudo install -o root -g root -m 600 discovery.yaml /etc/kubernetes/discovery.yaml 2>/dev/null
    if [ ! -f /etc/kubernetes/discovery.yaml ]; then
      attempt=$((attempt+1))
      sleep 10
    fi
  done
  cat << EOF > kubeadmjoin.yaml
apiVersion: kubeadm.k8s.io/v1beta3
caCertPath: /etc/kubernetes/pki/ca.crt
discovery:
  file:
    kubeConfigPath: /etc/kubernetes/discovery.yaml
  timeout: 5m0s
  tlsBootstrapToken: ${KUBEADM_TOKEN}
kind: JoinConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: external
controlPlane:
  certificateKey: ${KUBEADM_CERTKEY}
EOF
  if sudo kubeadm join "${K8S_CONTROLPLANE_VIP}":6443 --config kubeadmjoin.yaml; then
    echo ">> Node ${HOSTNAME} successfully initialized!"
    touch .k8s-node-success
    mkdir -p "${HOME}"/.kube
    sudo cp -i /etc/kubernetes/admin.conf "${HOME}"/.kube/config
    sudo chown "$(id -u):$(id -g)" "${HOME}"/.kube/config
    rm -f discovery.yaml env.txt kubeadmjoin.yaml initialize-controlplane.sh
  else
    echo ">> [ERROR] Cluster initialization unsuccessful on ${HOSTNAME}! <<"
    exit 1
  fi
fi