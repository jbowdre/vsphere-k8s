#!/bin/bash -eu

source ./env.txt

echo ">> Waiting up to 5 minutes for initial control-plane node..."
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
echo ">> Waiting up to 10 minutes for all control-plane nodes..."
attempts_max=60
attempt=0
until curl --fail "http://${K8S_CONTROLPLANE_VIP}:8000/.k8s-controlplane-success" 2>/dev/null; do
  if [ ${attempt} -eq ${attempts_max} ]; then
    echo ">> [ERROR] Timeout waiting for control-plane nodes! <<"
    exit 1
  fi
  attempt=$((attempt+1))
  sleep 10
done
echo ">> Continuing after $((attempt*10)) seconds."
echo ">> Retrieving cluster discovery config..."
attempts_max=6
attempt=0
until [ -f ~/discovery.yaml ] || [ ${attempt} -eq ${attempts_max} ]; do
  wget "http://${K8S_CONTROLPLANE_VIP}:8000/discovery.yaml"
  sleep 2
  if ! [ -f ~/discovery.yaml ]; then
    echo ">> Unable to retrieve config..."
    attempt=$((attempt+1))
    sleep 8
  fi
done
if ! [ -f ~/discovery.yaml ]; then
  echo ">> Timeout reached while retrieving config!"
  echo "Exiting."
  exit 1
fi
sudo install -o root -g root -m 600 discovery.yaml /etc/kubernetes/discovery.yaml
echo ">> Successfully discovered cluster!"
echo ">> Discovered cluster!"
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
EOF
if sudo kubeadm join "${K8S_CONTROLPLANE_VIP}":6443 --config kubeadmjoin.yaml; then
  echo ">> Node ${HOSTNAME} successfully initialized!"
  touch .k8s-node-success
  rm -f env.txt kubeadmjoin.yaml discovery.yaml join-workers.sh
else
  echo ">> [ERROR] Cluster initialization unsuccessful on ${HOSTNAME}! <<"
  exit 1
fi
