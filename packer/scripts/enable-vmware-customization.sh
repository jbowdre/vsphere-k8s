#!/bin/bash -eu
echo '>> Enabling legacy VMware Guest Customization...'
echo 'disable_vmware_customization: true' | sudo tee -a /etc/cloud/cloud.cfg
sudo vmware-toolbox-cmd config set deployPkg enable-custom-scripts true
