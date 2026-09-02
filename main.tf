terraform {
  required_version = ">= 1.5"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

locals {
  servers = {
    for i in range(var.server_count) : "rke2-server-${i + 1}" => {
      memory_mb    = var.server_memory_mb
      vcpu         = var.server_vcpu
      disk_size_gb = var.server_disk_gb
    }
  }
  agents = {
    for i in range(var.agent_count) : "rke2-agent-${i + 1}" => {
      memory_mb    = var.agent_memory_mb
      vcpu         = var.agent_vcpu
      disk_size_gb = var.agent_disk_gb
    }
  }
  all_nodes = merge(local.servers, local.agents)
}

# Downloaded once, then every node clones off this as a backing (COW) volume.
# Ubuntu's cloud image (unlike Rocky's) reliably boots on legacy BIOS, so we
# can stick with the provider's default i440fx machine type and the simple
# built-in `cloudinit` attachment (IDE, which i440fx supports fine) -- no
# need for the q35/UEFI/SCSI workarounds we went through for Rocky.
resource "libvirt_volume" "os_base" {
  name   = "ubuntu-base.qcow2"
  pool   = var.storage_pool
  source = var.os_image_url
  format = "qcow2"
}

resource "libvirt_volume" "node_disk" {
  for_each       = local.all_nodes
  name           = "${each.key}.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.os_base.id
  size           = each.value.disk_size_gb * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "init" {
  for_each  = local.all_nodes
  name      = "${each.key}-cloudinit.iso"
  pool      = var.storage_pool
  user_data = templatefile("${path.module}/cloud-init/user-data.tpl", {
    hostname = each.key
    ssh_key  = var.ssh_public_key
  })
}

resource "libvirt_domain" "node" {
  for_each  = local.all_nodes
  name      = each.key
  memory    = each.value.memory_mb
  vcpu      = each.value.vcpu
  cloudinit = libvirt_cloudinit_disk.init[each.key].id

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node_disk[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}
