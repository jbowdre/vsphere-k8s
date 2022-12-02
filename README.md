# Vanilla Kubernetes on VMware vSphere

## Packer
1. `cd packer`.
2. Copy `linux-server.example.pkrvars.hcl` to `linux-server.auto.pkrvars.hcl` and update it as appropriate for your environment.
2. Put the SSH private key which corresponds to the `build_key` variable in `packer_cache/ssh_private_key_packer.pem`.
3. Run it with `packer build -on-error=abort -force .`.

## Terraform
1. `cd terraform`.
2. Copy `terraform.example.tfvars` to `terraform.auto.tfvars` and update it as appropriate for your environment.
3. Run it with `terraform apply`.