# Vanilla Kubernetes on VMware vSphere

## Prerequisites
1. [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) installed on your system
2. Account in vSphere with [appropriate privileges](https://developer.hashicorp.com/packer/plugins/builders/vsphere/vsphere-iso#required-vsphere-privileges)
3. [Ubuntu Server 20.04 installation ISO](https://releases.ubuntu.com/20.04.5/) copied to a vSphere datastore

## Packer
1. `cd packer`.
2. Copy `ubuntu-k8s.example.pkrvars.hcl` to `ubuntu-k8s.auto.pkrvars.hcl` and update it as appropriate for your environment.
2. Put the SSH private key which corresponds to the `build_key` variable in `packer_cache/ssh_private_key_packer.pem`.
3. Place any needed internal CA PEM-formatted certs (with `.cer` file extension) in `certs/`. 
4. Run it with `packer build -on-error=abort -force .`.

## Terraform
1. `cd terraform`.
2. Copy `terraform.example.tfvars` to `terraform.auto.tfvars` and update it as appropriate for your environment.
3. Initialize Terraform: `terraform init`.
3. Create the deployment with `terraform apply`.