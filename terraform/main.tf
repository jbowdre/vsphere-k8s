terraform {
  required_providers {
    vsphere = {
      version = "2.2.0"
    }
  }
}

provider "vsphere" {
  user = var.vsphere-user
  password = var.vsphere-password
  vsphere_server = var.vsphere-server
  allow_unverified_ssl = var.vsphere-unverified-ssl
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere-datacenter
}

data "vsphere_datastore" "datastore" {
  name = var.vm-datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "k8s-datastore" {
  name = var.k8s-datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name = var.vsphere-cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name = var.vm-network-name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name = "/${var.vsphere-datacenter}/vm/${var.vsphere-template-folder}/${var.vm-template-name}"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "random_shuffle" "certkey" {
  input = ["a", "b", "c", "d", "e", "f", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
  result_count = 64
}

resource "random_string" "token1" {
  length = 6
  special = false
  upper = false
}

resource "random_string" "token2" {
  length = 16
  special = false
  upper = false
}

locals {
  kubeadm-certkey = join("", random_shuffle.certkey.result)
  kubeadm-token = join(".", [random_string.token1.result, random_string.token2.result])
  k8s-initial-node = "${var.vm-control-name}-1"
  k8s-node-count = "${var.vm-control-count + var.vm-worker-count}"
}

resource "vsphere_virtual_machine" "control" {
  count = var.vm-control-count
  name = "${var.vm-control-name}-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id = data.vsphere_datastore.datastore.id
  folder = var.vm-folder

  num_cpus = var.vm-control-cpu
  memory = var.vm-control-ram
  guest_id = data.vsphere_virtual_machine.template.guest_id
  firmware = data.vsphere_virtual_machine.template.firmware
  hardware_version = data.vsphere_virtual_machine.template.hardware_version
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  wait_for_guest_net_timeout = 10

  extra_config = {
    "disk.EnableUUID" = "TRUE"
  }

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label = "${var.vm-control-name}-${count.index +1}-disk"
    size = var.vm-control-disk-size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      timeout = 0
      
      linux_options {
        host_name = "${var.vm-control-name}-${count.index +1}"
        domain = var.vm-domain
      }

      network_interface {
        ipv4_address = "${var.vm-network-address != "0.0.0.0/0" ? cidrhost(var.vm-network-address, var.vm-control-ip-address-start + count.index) : ""}"
        ipv4_netmask = "${var.vm-network-address != "0.0.0.0/0" ? element(split("/", var.vm-network-address), 1) : 0}"
      }

      ipv4_gateway = var.vm-network-gateway
      dns_server_list = var.vm-network-dns-servers
      dns_suffix_list = [var.vm-domain]
    }
  }

  connection {
    type = "ssh"
    user = "${var.k8s-username}"
    private_key = file("${var.k8s-ssh-key-file}")
    host = "${self.default_ip_address}"
  }

  provisioner "file" {
    source = "scripts/initialize-controlplane.sh"
    destination = "/home/${var.k8s-username}/initialize-controlplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo export K8S_INITIAL_NODE=\"'${local.k8s-initial-node}'\" >> env.txt",
      "echo export KUBEADM_TOKEN=\"'${local.kubeadm-token}'\" >> env.txt",
      "echo export KUBEADM_CERTKEY=\"'${local.kubeadm-certkey}'\" >> env.txt",
      "echo export K8S_VER=\"'${var.k8s-version}'\" >> env.txt",
      "echo export K8S_SERVICE_CIDR=\"'${var.k8s-service-cidr}'\" >> env.txt",
      "echo export K8S_POD_CIDR=\"'${var.k8s-pod-cidr}'\" >> env.txt",
      "echo export K8S_CLUSTER_NAME=\"'${var.k8s-cluster-name}'\" >> env.txt",
      "echo export K8S_CONTROLPLANE_VIP=\"'${var.k8s-controlplane-vip}'\" >> env.txt",
      "echo export K8S_CONTROLPLANE_COUNT=\"'${var.vm-control-count}'\" >> env.txt",
      "echo export KUBEVIP_VER=\"'${var.k8s-kubevip-version}'\" >> env.txt",
      "echo export K8S_NODE_COUNT=\"'${local.k8s-node-count}'\" >> env.txt",
      "echo export VCENTER_SERVER=\"'${var.vsphere-server}'\" >> env.txt",
      "echo export VCENTER_USERNAME=\"'${var.vsphere-user}'\" >> env.txt",
      "echo export VCENTER_PASSWORD=\"'${var.vsphere-password}'\" >> env.txt",
      "echo export VCENTER_DATACENTER=\"'${var.vsphere-datacenter}'\" >> env.txt",
      "chmod +x /home/${var.k8s-username}/initialize-controlplane.sh",
      "/home/${var.k8s-username}/initialize-controlplane.sh"
    ]
  }
}

resource "vsphere_virtual_machine" "worker" {
  count = var.vm-worker-count
  name = "${var.vm-worker-name}-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id = data.vsphere_datastore.datastore.id
  folder = "/${var.vsphere-datacenter}/vm/${var.vm-folder}"

  num_cpus = var.vm-worker-cpu
  memory = var.vm-worker-ram
  guest_id = data.vsphere_virtual_machine.template.guest_id
  firmware = data.vsphere_virtual_machine.template.firmware
  hardware_version = data.vsphere_virtual_machine.template.hardware_version
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  wait_for_guest_net_timeout = 10

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label = "${var.vm-worker-name}-${count.index +1}-disk"
    size = var.vm-worker-disk-size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      timeout = 0
      
      linux_options {
        host_name = "${var.vm-worker-name}-${count.index +1}"
        domain = var.vm-domain
      }

      network_interface {
        ipv4_address = "${var.vm-network-address != "0.0.0.0/0" ? cidrhost(var.vm-network-address, var.vm-worker-ip-address-start + count.index) : ""}"
        ipv4_netmask = "${var.vm-network-address != "0.0.0.0/0" ? element(split("/", var.vm-network-address), 1) : 0}"
      }

      ipv4_gateway = var.vm-network-gateway
      dns_server_list = var.vm-network-dns-servers
      dns_suffix_list = [var.vm-domain]
    }
  }
  connection {
    type = "ssh"
    user = "${var.k8s-username}"
    private_key = file("${var.k8s-ssh-key-file}")
    host = "${self.default_ip_address}"
  }

  provisioner "file" {
    source = "scripts/join-workers.sh"
    destination = "/home/${var.k8s-username}/join-workers.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo export KUBEADM_TOKEN=\"'${local.kubeadm-token}'\" >> env.txt",
      "echo export K8S_CONTROLPLANE_VIP=\"'${var.k8s-controlplane-vip}'\" >> env.txt",
      "echo export K8S_CONTROLPLANE_COUNT=\"'${var.vm-control-count}'\" >> env.txt",
      "chmod +x /home/${var.k8s-username}/join-workers.sh",
      "/home/${var.k8s-username}/join-workers.sh"
    ]
  }
}
