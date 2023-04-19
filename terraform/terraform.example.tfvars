# Connection settings
vsphere-user = "terraform"
vsphere-password = "VMware1!"
vsphere-server = "vcenter.lab.local"
vsphere-unverified-ssl = "true"

# Deployment options
vsphere-datacenter = "Datacenter 01"
vsphere-cluster = "cluster-01"
vsphere-template-folder = "_Templates"
vm-template-name = "k8s-u2004"
vm-folder = "kubes"
vm-datastore = "datastore-01"
vm-network-name = "network-01"
vm-network-address = "192.168.1.0/24"
vm-network-gateway = "192.168.1.1"
vm-network-dns-servers = ["192.168.1.5"]
vm-domain = "lab.local"

# Control plane specs
vm-control-count = "3"
vm-control-cpu = "2"
vm-control-ram = "4096"
vm-control-disk-size = "30"
vm-control-ip-address-start = "60"
vm-control-name = "k8s-control"

# Worker specs
vm-worker-count = "3"
vm-worker-cpu = "4"
vm-worker-ram = "8192"
vm-worker-disk-size = "30"
vm-worker-ip-address-start = "64"
vm-worker-name = "k8s-worker"

# Kubernetes specs
k8s-version = "1.25.3"
k8s-cluster-name = "vsphere-k8s"
k8s-datastore = "datastore-01"
k8s-pod-cidr = "10.244.0.0/16"
k8s-service-cidr = "10.96.0.0/12"
k8s-kubevip-version = "v0.5.6"
k8s-controlplane-vip = "vsphere-k8s.lab.local"
k8s-username = "admin"
k8s-ssh-key-file = "../packer/packer_cache/ssh_private_key_packer.pem"

