#!/bin/bash -eu
chmod 600 ~/.ssh/id_ed25519 

echo ">> Installing Kubernetes components..."

# Configure and enable kernel modules
echo ".. configure kernel modules"
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure networking
echo ".. configure networking"
cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Setup containerd
echo ".. setup containerd"
sudo apt-get update && sudo apt-get install -y containerd apt-transport-https jq
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Disable swap
echo ".. disable swap"
sudo sed -i '/[[:space:]]swap[[:space:]]/ s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Install Kubernetes
echo ".. install kubernetes version ${KUBEVERSION}"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet="${KUBEVERSION}"-00 kubeadm="${KUBEVERSION}"-00 kubectl="${KUBEVERSION}"-00
sudo apt-mark hold kubelet kubeadm kubectl
