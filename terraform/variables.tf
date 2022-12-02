# vSphere connection options

variable "vsphere-user" {
  type = string
  description = "vSphere user name"
}

variable "vsphere-password" {
  type = string
  description = "vSphere password"
}

variable "vsphere-server" {
  type = string
  description = "vCenter server FQDN or IP"
}

variable "vsphere-unverified-ssl" {
  type = string
  description = "Allow connecting to vCenter with self-signed certificate (true/false)"
}

# Deployment options
variable "vsphere-datacenter" {
  type = string
  description = "vSphere datacenter"
}

variable "vsphere-cluster" {
  type = string
  description = "vSphere cluster"
  default = ""
}

variable "vsphere-template-folder" {
  type = string
  description = "Folder which holds the templates"
}

variable "vm-template-name" {
  type = string
  description = "Name of the template to be cloned"
}

variable "vm-folder" {
  type = string
  description = "Folder to hold the new VMs"
}

variable "vm-datastore" {
  type = string
  description = "vSphere datastore to hold the VMs"
}

variable "vm-network-name" {
  type = string
  description = "Network attached to the VMs"
}

variable "vm-network-address" {
  type = string
  description = "Network address with mask (ex: 192.168.1.0/24)"
}

variable "vm-network-gateway" {
  type = string
  description = "IPv4 gateway address"
}

variable "vm-network-dns-servers" {
  type = list
  description = "List of DNS servers"
}

variable "vm-domain" {
  type = string
  description = "Domain name for the VM"
  default = ""
}

# Control plane specs
variable "vm-control-count" {
  type = string
  description = "Number of control plane nodes"
  default = "1"
}

variable "vm-control-cpu" {
  type = string
  description = "Number of vCPUs for the control plane node(s)"
  default = "2"
}

variable "vm-control-ram" {
  type = string
  description = "Megabytes of RAM for the control plane node(s)"
  default = "2048"
}

variable "vm-control-disk-size" {
  type = string
  description = "Gigabytes of storage for the control plane node(s) disk"
}

variable "vm-control-ip-address-start" {
  type = string
  description = "Last octet of the first IP available to control plane nodes"
}

variable "vm-control-name" {
  type = string
  description = "Base name of the control plane node(s)"
}

# Worker specs
variable "vm-worker-count" {
  type = string
  description = "Number of worker nodes"
  default = "2"
}

variable "vm-worker-cpu" {
  type = string
  description = "Number of vCPUs for the worker node(s)"
  default = "1"
}

variable "vm-worker-ram" {
  type = string
  description = "Megabytes of RAM for the worker node(s)"
  default = "1024"
}

variable "vm-worker-disk-size" {
  type = string
  description = "Gigabytes of storage for the worker node(s) disk"
}

variable "vm-worker-ip-address-start" {
  type = string
  description = "Last octet of the first IP available to worker nodes"
}

variable "vm-worker-name" {
  type = string
  description = "Base name of the worker node(s)"
}

# Kubernetes specs
variable "k8s-version" {
  type = string
  description = "Numerical version of Kubernetes to be used"
  default = "1.25.3"
}

variable "k8s-cluster-name" {
  type = string
  description = "Display name for the new cluster"
}
variable "k8s-datastore" {
  type = string
  description = "vSphere datastore to hold K8s persistent volumes"
}

variable "k8s-pod-cidr" {
  type = string
  description = "Network CIDR range used for pod networking (default: 10.244.0.0/16)"
  default = "10.244.0.0/16"
}

variable "k8s-service-cidr" {
  type = string
  description = "Network CIDR range used for service networking (default: 10.96.0.0/12)"
  default = "10.96.0.0/12"
}

variable "k8s-kubevip-version" {
  type = string
  description = "Version tag of the desired kube-vip release (ex: v0.5.6)"
  default = "latest"
}

variable "k8s-controlplane-vip" {
  type = string
  description = "IP or FQDN to be assigned to the integrated kube-vip load balancer"
}

variable "k8s-username" {
  type = string
  description = "Username used to log in to the K8s nodes for cluster bootstrapping"
}

variable "k8s-ssh-key-file" {
  type = string
  description = "Path to a file containing the SSH private key used for cluster bootstrapping"
}
