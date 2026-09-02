#cloud-config
hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

users:
  - name: ubuntu
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}

ssh_pwauth: false
disable_root: true

package_update: true
package_upgrade: false
packages:
  - qemu-guest-agent
  - curl
  - tar
  - iptables

# growpart/resizefs run automatically as default cloud-init modules on
# Ubuntu's cloud image, so the root filesystem expands to fill the disk
# without any extra runcmd steps.

runcmd:
  - systemctl enable --now qemu-guest-agent
  - swapoff -a
  - modprobe br_netfilter
  - modprobe overlay
  - echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/99-kubernetes.conf
  - echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-kubernetes.conf
  - sysctl --system
