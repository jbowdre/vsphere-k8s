#!/bin/bash -eu
echo '>> Checking for and installing updates...'
sudo apt-get update && sudo apt-get -y upgrade
echo '>> Rebooting!'
sudo reboot