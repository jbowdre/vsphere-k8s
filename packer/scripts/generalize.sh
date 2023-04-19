#!/bin/bash -eu
# Prepare a VM to become a template.

echo '>> Clearing audit logs...'
sudo sh -c 'if [ -f /var/log/audit/audit.log ]; then
  cat /dev/null > /var/log/audit/audit.log
  fi'
sudo sh -c 'if [ -f /var/log/wtmp ]; then
  cat /dev/null > /var/log/wtmp
  fi'
sudo sh -c 'if [ -f /var/log/lastlog ]; then
  cat /dev/null > /var/log/lastlog
  fi'
sudo sh -c 'if [ -f /etc/logrotate.conf ]; then
  logrotate -f /etc/logrotate.conf 2>/dev/null
  fi'
sudo rm -rf /var/log/journal/*
sudo rm -f /var/lib/dhcp/*
sudo find /var/log -type f -delete

echo '>> Clearing persistent udev rules...'
sudo sh -c 'if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
  rm /etc/udev/rules.d/70-persistent-net.rules
  fi'

echo '>> Clearing temp dirs...'
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo '>> Clearing host keys...'
sudo rm -f /etc/ssh/ssh_host_*

echo '>> Removing Packer SSH key...'
sed -i '/packer_key/d' ~/.ssh/authorized_keys

echo '>> Clearing machine-id...'
sudo truncate -s 0 /etc/machine-id
if [ -f /var/lib/dbus/machine-id ]; then
  sudo rm -f /var/lib/dbus/machine-id
  sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
fi

echo '>> Clearing shell history...'
unset HISTFILE
history -cw
echo > ~/.bash_history
sudo rm -f /root/.bash_history
