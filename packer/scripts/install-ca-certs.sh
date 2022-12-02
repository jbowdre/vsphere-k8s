#!/bin/bash -eu

echo '>> Installing custom certificates...'
sudo cp /tmp/certs/* /usr/local/share/ca-certificates/
cd /usr/local/share/ca-certificates/
for file in *.cer; do
  sudo mv -- "$file" "${file%.cer}.crt"
done
sudo /usr/sbin/update-ca-certificates

