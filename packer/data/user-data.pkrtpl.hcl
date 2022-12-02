#cloud-config
autoinstall:
  version: 1
  early-commands:
    - sudo systemctl stop ssh
  locale: ${ vm_guest_os_language }
  keyboard:
    layout: ${ vm_guest_os_keyboard }
  network:
    network:
      version: 2
      ethernets:
        mainif:
          match:
            name: e*
          critical: true
          dhcp4: true
          dhcp-identifier: mac
  ssh:
    install-server: true
    allow-pw: true
%{ if length( apt_mirror ) > 0 ~}
  apt:
    primary:
      - arches: [default]
        uri: "${ apt_mirror }"
%{ endif ~}
%{ if length( apt_packages ) > 0 ~}
  packages:
%{ for package in apt_packages ~}
    - ${ package }
%{ endfor ~}
%{ endif ~}
  storage:
    config:
      - ptable: gpt
        path: /dev/sda
        wipe: superblock
        type: disk
        id: disk-sda
      - device: disk-sda
        size: 1024M
        wipe: superblock
        flag: boot
        number: 1
        grub_device: true
        type: partition
        id: partition-0
      - fstype: fat32
        volume: partition-0
        label: EFIFS
        type: format
        id: format-efi
      - device: disk-sda
        size: 1024M
        wipe: superblock
        number: 2
        type: partition
        id: partition-1
      - fstype: xfs
        volume: partition-1
        label: BOOTFS
        type: format
        id: format-boot
      - device: disk-sda
        size: -1
        wipe: superblock
        number: 3
        type: partition
        id: partition-2
      - name: sysvg
        devices:
          - partition-2
        type: lvm_volgroup
        id: lvm_volgroup-0
      - name: home
        volgroup: lvm_volgroup-0
        size: 4096M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-home
      - fstype: xfs
        volume: lvm_partition-home
        type: format
        label: HOMEFS
        id: format-home
      - name: tmp
        volgroup: lvm_volgroup-0
        size: 3072M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-tmp
      - fstype: xfs
        volume: lvm_partition-tmp
        type: format
        label: TMPFS
        id: format-tmp
      - name: var
        volgroup: lvm_volgroup-0
        size: 4096M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-var
      - fstype: xfs
        volume: lvm_partition-var
        type: format
        label: VARFS
        id: format-var
      - name: log
        volgroup: lvm_volgroup-0
        size: 4096M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-log
      - fstype: xfs
        volume: lvm_partition-log
        type: format
        label: LOGFS
        id: format-log
      - name: audit
        volgroup: lvm_volgroup-0
        size: 4096M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-audit
      - fstype: xfs
        volume: lvm_partition-audit
        type: format
        label: AUDITFS
        id: format-audit
      - name: root
        volgroup: lvm_volgroup-0
        size: -1
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-root
      - fstype: xfs
        volume: lvm_partition-root
        type: format
        label: ROOTFS
        id: format-root
      - path: /
        device: format-root
        type: mount
        id: mount-root
      - path: /boot
        device: format-boot
        type: mount
        id: mount-boot
      - path: /boot/efi
        device: format-efi
        type: mount
        id: mount-efi
      - path: /home
        device: format-home
        type: mount
        id: mount-home
      - path: /tmp
        device: format-tmp
        type: mount
        id: mount-tmp
      - path: /var
        device: format-var
        type: mount
        id: mount-var
      - path: /var/log
        device: format-log
        type: mount
        id: mount-log
      - path: /var/log/audit
        device: format-audit
        type: mount
        id: mount-audit
  user-data:
    package_upgrade: true
    disable_root: true
    timezone: ${ vm_guest_os_timezone }
    hostname: ${ vm_guest_os_hostname }
    users:
      - name: ${ build_username }
        passwd: "${ build_password }"
        groups: [adm, cdrom, dip, plugdev, lxd, sudo]
        lock-passwd: false
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
%{ if length( build_key ) > 0 ~}
        ssh_authorized_keys:
          - ${ build_key }
%{ endif ~}
