#!/bin/sh -eu
echo '>> Preserving network settings...'
echo 'manual_cache_clean: True' | sudo tee -a /etc/cloud/cloud.cfg