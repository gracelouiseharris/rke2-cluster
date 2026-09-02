variable "libvirt_uri" {
  description = "libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

variable "storage_pool" {
  description = "libvirt storage pool to create volumes in (check with `virsh pool-list --all`)"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "libvirt network to attach VMs to (check with `virsh -c qemu:///system net-list --all`)"
  type        = string
  default     = "rke2-lab-net"
}

variable "os_image_url" {
  description = "URL of the Ubuntu Server 24.04 LTS cloud image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "ssh_public_key" {
  description = "Your SSH public key, injected into every VM via cloud-init"
  type        = string
}

variable "server_count" {
  description = "Number of RKE2 server (control-plane) nodes"
  type        = number
  default     = 1
}

variable "agent_count" {
  description = "Number of RKE2 agent (worker) nodes"
  type        = number
  default     = 2
}

variable "server_memory_mb" {
  type    = number
  default = 4096
}

variable "server_vcpu" {
  type    = number
  default = 2
}

variable "server_disk_gb" {
  type    = number
  default = 40
}

variable "agent_memory_mb" {
  type    = number
  default = 8192
}

variable "agent_vcpu" {
  type    = number
  default = 4
}

variable "agent_disk_gb" {
  type    = number
  default = 60
}
