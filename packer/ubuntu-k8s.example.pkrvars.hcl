/*
    DESCRIPTION:
    Ubuntu Server 20.04 LTS Kubernetes node variables used by the Packer Plugin for VMware vSphere (vsphere-iso).
*/

// vSphere Credentials
vsphere_endpoint            = "vcenter.lab.local"
vsphere_username            = "packer"
vsphere_password            = "VMware1!"
vsphere_insecure_connection = true

// vSphere Settings
vsphere_datacenter = "Datacenter 01"
vsphere_cluster    = "cluster-01"
vsphere_datastore  = "datastore-01"
vsphere_network    = "network-01"
vsphere_folder     = "_Templates"

// Guest Operating System Settings
vm_guest_os_language = "en_US"
vm_guest_os_keyboard = "us"
vm_guest_os_timezone = "America/Chicago"
vm_guest_os_type = "ubuntu64Guest"

// Virtual Machine Hardware Settings
vm_name                   = "k8s-u2004"
vm_firmware               = "efi-secure"
vm_cdrom_type             = "sata"
vm_cpu_count              = 2
vm_cpu_cores              = 1
vm_cpu_hot_add            = true
vm_mem_size               = 2048
vm_mem_hot_add            = true
vm_disk_size              = 30720
vm_disk_controller_type   = ["pvscsi"]
vm_disk_thin_provisioned  = true
vm_network_card           = "vmxnet3"
common_vm_version           = 19
common_tools_upgrade_policy = true
common_remove_cdrom         = true

// Template and Content Library Settings
common_template_conversion         = true
common_content_library_name        = null
common_content_library_ovf         = false
common_content_library_destroy     = true
common_content_library_skip_export = true

// OVF Export Settings
common_ovf_export_enabled   = false
common_ovf_export_overwrite = true
common_ovf_export_path      = ""

// Removable Media Settings
common_iso_datastore    = "datastore-01"
iso_url                 = null
iso_path                = "_ISO"
iso_file                = "ubuntu-20.04.5-live-server-amd64.iso"
iso_checksum_type       = "sha256"
iso_checksum_value      = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4"

// Boot Settings
vm_boot_order       = "disk,cdrom"
vm_boot_wait        = "4s"
vm_boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

// Communicator Settings
communicator_port       = 22
communicator_timeout    = "20m"
common_ip_wait_timeout  = "20m"
common_shutdown_timeout = "15m"
vm_shutdown_command     = "sudo /usr/sbin/shutdown -P now"
build_remove_keys       = true
build_username          = "admin"
build_password          = "VMware1!"
ssh_keys                = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpLvpxilPjpCahAQxs4RQgv+Lb5xObULXtwEoimEBpA builder"
]

// Provisioner Settings
post_install_scripts = [
  "scripts/wait-for-cloud-init.sh",
  "scripts/cleanup-subiquity.sh",
  "scripts/install-ca-certs.sh",
  "scripts/disable-multipathd.sh",
  "scripts/disable-release-upgrade-motd.sh",
  "scripts/persist-cloud-init-net.sh",
  "scripts/configure-sshd.sh",
  "scripts/install-k8s.sh",
  "scripts/update-packages.sh"
]

pre_final_scripts = [
  "scripts/cleanup-cloud-init.sh",
  "scripts/enable-vmware-customization.sh",
  "scripts/zero-disk.sh",
  "scripts/generalize.sh"
]

// Kubernetes Settings
k8s_version = "1.25.3"