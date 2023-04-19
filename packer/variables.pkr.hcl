/*
    DESCRIPTION:
    Ubuntu Server 20.04 LTS variables using the Packer Builder for VMware vSphere (vsphere-iso).
*/

//  BLOCK: variable
//  Defines the input variables.

// vSphere Credentials
variable "vsphere_endpoint" {
  type        = string
  description = "The fully qualified domain name or IP address of the vCenter Server instance. ('vcenter.lab.local')"
}

variable "vsphere_username" {
  type        = string
  description = "The username to login to the vCenter Server instance. ('packer')"
}

variable "vsphere_password" {
  type        = string
  description = "The password for the login to the vCenter Server instance."
  sensitive   = true
}

variable "vsphere_insecure_connection" {
  type        = bool
  description = "Do not validate vCenter Server TLS certificate."
  default     = true
}

// vSphere Settings
variable "vsphere_datacenter" {
  type        = string
  description = "The name of the target vSphere datacenter. ('Lab Datacenter')"
}

variable "vsphere_cluster" {
  type        = string
  description = "The name of the target vSphere cluster. ('cluster-01')"
}

variable "vsphere_datastore" {
  type        = string
  description = "The name of the target vSphere datastore. ('datastore-01')"
}

variable "vsphere_network" {
  type        = string
  description = "The name of the target vSphere network. ('network-192.168.1.0')"
}

variable "vsphere_folder" {
  type        = string
  description = "The name of the target vSphere folder. ('_Templates')"
}

// Virtual Machine Settings
variable "vm_name" {
  type        = string
  description = "Name of the new VM to create."
}

variable "vm_guest_os_language" {
  type        = string
  description = "The guest operating system lanugage."
  default     = "en_US"
}

variable "vm_guest_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard input."
  default     = "us"
}

variable "vm_guest_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "UTC"
}

variable "vm_guest_os_type" {
  type        = string
  description = "The guest operating system type. ('ubuntu64Guest')"
}

variable "vm_firmware" {
  type        = string
  description = "The virtual machine firmware. ('efi-secure'. 'efi', or 'bios')"
  default     = "efi-secure"
}

variable "vm_cdrom_type" {
  type        = string
  description = "The virtual machine CD-ROM type. ('sata', or 'ide')"
  default     = "sata"
}

variable "vm_cpu_count" {
  type        = number
  description = "The number of virtual CPUs. ('2')"
}

variable "vm_cpu_cores" {
  type        = number
  description = "The number of virtual CPUs cores per socket. ('1')"
}

variable "vm_cpu_hot_add" {
  type        = bool
  description = "Enable hot add CPU."
  default     = true
}

variable "vm_mem_size" {
  type        = number
  description = "The size for the virtual memory in MB. ('2048')"
}

variable "vm_mem_hot_add" {
  type        = bool
  description = "Enable hot add memory."
  default     = true
}

variable "vm_disk_size" {
  type        = number
  description = "The size for the virtual disk in MB. ('61440' = 60GB)"
  default     = 61440
}

variable "vm_disk_controller_type" {
  type        = list(string)
  description = "The virtual disk controller types in sequence. ('pvscsi')"
  default     = ["pvscsi"]
}

variable "vm_disk_thin_provisioned" {
  type        = bool
  description = "Thin provision the virtual disk."
  default     = true
}

variable "vm_disk_eagerly_scrub" {
  type        = bool
  description = "Enable VMDK eager scrubbing for VM."
  default     = false
}

variable "vm_network_card" {
  type        = string
  description = "The virtual network card type. ('vmxnet3' or 'e1000e')"
  default     = "vmxnet3"
}

variable "common_vm_version" {
  type        = number
  description = "The vSphere virtual hardware version. (e.g. '19')"
}

variable "common_tools_upgrade_policy" {
  type        = bool
  description = "Upgrade VMware Tools on reboot."
  default     = true
}

variable "common_remove_cdrom" {
  type        = bool
  description = "Remove the virtual CD-ROM(s)."
  default     = true
}

// Template and Content Library Settings
variable "common_template_conversion" {
  type        = bool
  description = "Convert the virtual machine to template. Must be 'false' for content library."
  default     = false
}

variable "common_content_library_name" {
  type        = string
  description = "The name of the target vSphere content library, if used. ('Lab-CL')"
  default     = null
}

variable "common_content_library_ovf" {
  type        = bool
  description = "Export to content library as an OVF template."
  default     = false
}

variable "common_content_library_destroy" {
  type        = bool
  description = "Delete the virtual machine after exporting to the content library."
  default     = true
}

variable "common_content_library_skip_export" {
  type        = bool
  description = "Skip exporting the virtual machine to the content library. Option allows for testing / debugging without saving the machine image."
  default     = false
}

// Snapshot Settings
variable "common_snapshot_creation" {
  type        = bool
  description = "Create a snapshot for Linked Clones."
  default     = false
}

variable "common_snapshot_name" {
  type        = string
  description = "Name of the snapshot to be created if create_snapshot is true."
  default     = "Created By Packer"
}

// OVF Export Settings
variable "common_ovf_export_enabled" {
  type        = bool
  description = "Enable OVF artifact export."
  default     = false
}

variable "common_ovf_export_overwrite" {
  type        = bool
  description = "Overwrite existing OVF artifact."
  default     = true
}

variable "common_ovf_export_path" {
  type        = string
  description = "Folder path for the OVF export."
}

// Removable Media Settings
variable "common_iso_datastore" {
  type        = string
  description = "The name of the source vSphere datastore for ISO images. ('datastore-iso-01')"
}

variable "iso_url" {
  type        = string
  description = "The URL source of the ISO image. ('https://releases.ubuntu.com/20.04.5/ubuntu-20.04.5-live-server-amd64.iso')"
}

variable "iso_path" {
  type        = string
  description = "The path on the source vSphere datastore for ISO image. ('ISOs/Linux')"
}

variable "iso_file" {
  type        = string
  description = "The file name of the ISO image used by the vendor. ('ubuntu-20.04.5-live-server-amd64.iso')"
}

variable "iso_checksum_type" {
  type        = string
  description = "The checksum algorithm used by the vendor. ('sha256')"
}

variable "iso_checksum_value" {
  type        = string
  description = "The checksum value provided by the vendor."
}

variable "cd_label" {
  type        = string
  description = "CD Label"
  default     = "cidata"
}

// Boot Settings
variable "vm_boot_order" {
  type        = string
  description = "The boot order for virtual machines devices. ('disk,cdrom')"
  default     = "disk,cdrom"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait before boot."
}

variable "vm_boot_command" {
  type        = list(string)
  description = "The virtual machine boot command."
  default     = []
}

variable "vm_shutdown_command" {
  type        = string
  description = "Command(s) for guest operating system shutdown."
  default     = null
}

variable "common_ip_wait_timeout" {
  type        = string
  description = "Time to wait for guest operating system IP address response."
}

variable "common_shutdown_timeout" {
  type        = string
  description = "Time to wait for guest operating system shutdown."
}

// Communicator Settings and Credentials
variable "build_username" {
  type        = string
  description = "The username to login to the guest operating system. ('admin')"
}

variable "build_password" {
  type        = string
  description = "The password to login to the guest operating system."
  sensitive   = true
}

variable "build_password_encrypted" {
  type        = string
  description = "The encrypted password to login the guest operating system."
  sensitive   = true
  default     = null
}

variable "ssh_keys" {
  type        = list(string)
  description = "List of public keys to be added to ~/.ssh/authorized_keys."
  sensitive   = true
  default     = []
}

variable "build_remove_keys" {
  type        = bool
  description = "If true, Packer will attempt to remove its temporary key from ~/.ssh/authorized_keys and /root/.ssh/authorized_keys"
  default     = true
}

// Communicator Settings
variable "communicator_port" {
  type        = string
  description = "The port for the communicator protocol."
}

variable "communicator_timeout" {
  type        = string
  description = "The timeout for the communicator protocol."
}

variable "communicator_insecure" {
  type        = bool
  description = "If true, do not check server certificate chain and host name"
  default     = true
}

variable "communicator_ssl" {
  type        = bool
  description = "If true, use SSL"
  default     = true
}

// Provisioner Settings
variable "cloud_init_apt_packages" {
  type        = list(string)
  description = "A list of apt packages to install during the subiquity cloud-init installer."
  default     = []
}

variable "cloud_init_apt_mirror" {
  type        = string
  description = "Sets the default apt mirror during the subiquity cloud-init installer."
  default     = ""
}

variable "post_install_scripts" {
  type        = list(string)
  description = "A list of scripts and their relative paths to transfer and run after OS install."
  default     = []
}

variable "pre_final_scripts" {
  type        = list(string)
  description = "A list of scripts and their relative paths to transfer and run before finalization."
  default     = []
}

// Kubernetes Settings
variable "k8s_version" {
  type        = string
  description = "Kubernetes version to be installed. Latest stable is listed at https://dl.k8s.io/release/stable.txt"
  default     = "1.25.3"
}