#!/bin/bash -eu
echo '>> Enabling legacy VMware Guest Customization...'
if grep -q 'disable_vmware_customization' /etc/cloud/cloud.cfg; then
  sudo sed -i 's/^disable_vmware_customization:.*$/disable_vmware_customization: True/' /etc/cloud/cloud.cfg
else
  echo 'disable_vmware_customization: true' | sudo tee -a /etc/cloud/cloud.cfg
fi
sudo vmware-toolbox-cmd config set deployPkg enable-custom-scripts true
