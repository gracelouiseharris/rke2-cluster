output "node_ips" {
  description = "Map of node name -> IP address (DHCP-assigned)"
  value = {
    for name, domain in libvirt_domain.node :
    name => try(domain.network_interface[0].addresses[0], "pending")
  }
}

output "server_names" {
  description = "Names of RKE2 server (control-plane) nodes"
  value       = keys(local.servers)
}

output "agent_names" {
  description = "Names of RKE2 agent (worker) nodes"
  value       = keys(local.agents)
}
