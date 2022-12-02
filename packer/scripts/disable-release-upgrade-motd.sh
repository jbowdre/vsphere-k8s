#!/bin/bash -eu
echo '>> Disabling release update MOTD...'
sudo chmod -x /etc/update-motd.d/91-release-upgrade
