# RKE2 VMs on libvirt/KVM (no sudo required)

Provisions Ubuntu 24.04 LTS VMs via Terraform against your existing
`qemu:///system` libvirt connection, ready to bootstrap into an RKE2
Kubernetes cluster.

## Prerequisites (already confirmed on this host)

- You're in the `kvm` and `libvirt` groups.
- `virsh list --all` works without sudo.
- A storage pool and network exist — verify names with:
  ```bash
  virsh pool-list --all
  virsh net-list --all
  ```
  If they're not both named `default`, set `storage_pool` /
  `network_name` in your `terraform.tfvars` accordingly.

## Install Terraform (no sudo)

```bash
mkdir -p ~/bin
curl -O https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
unzip terraform_1.9.8_linux_amd64.zip -d ~/bin
export PATH="$HOME/bin:$PATH"   # add to ~/.bashrc to persist
```

## Set up

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: paste your SSH public key (cat ~/.ssh/id_ed25519.pub)

terraform init
terraform plan
terraform apply
```

The `libvirt` provider binary itself is downloaded by `terraform init`
into your user-local `.terraform` directory — no sudo needed for that
either.

## After apply

```bash
terraform output node_ips
```

You'll get a map of node name -> IP (DHCP-assigned from the libvirt
network). SSH in as the `ubuntu` user:

```bash
ssh ubuntu@<ip>
```

## Next: bootstrap RKE2

Once the VMs are up, RKE2 install is just a script per node — Terraform's
job (creating the machines) is done at this point. Rough shape:

1. **First server node** (`rke2-server-1`):
   ```bash
   curl -sfL https://get.rke2.io | sudo sh -
   sudo systemctl enable --now rke2-server.service
   ```
   Grab the join token:
   ```bash
   sudo cat /var/lib/rancher/rke2/server/node-token
   ```

2. **Additional server nodes** (for HA): install the same way, but set
   `server: https://<first-server-ip>:9345` and `token: <token>` in
   `/etc/rancher/rke2/config.yaml` before starting the service.

3. **Agent nodes**:
   ```bash
   curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -
   ```
   with the same `server`/`token` config, then:
   ```bash
   sudo systemctl enable --now rke2-agent.service
   ```

Happy to write this whole bootstrap as an Ansible playbook or a
`remote-exec`/`file` provisioner block in Terraform if you'd rather not
do it by hand across 5 nodes — just say the word.

## Cleanup

```bash
terraform destroy
```
