variable "name" {
  description = "VPN gateway name"
}

variable "project_id" {}

variable "region" {
  description = "The region this gateway should sit in"
}

variable "vpn_network_name" {
  description = "The name of the network this VPN gateway is accepting traffic for"
}

variable "vpn_static_ip_name" {
  description = "External IP address"
}

variable "vpn_tunnel1_name" {
  description = "The VPN tunnel #1 name"
}

variable "vpn_tunnel1_peer_ip" {
  description = "IP address of the peer VPN gateway. On AWS is Virtual Private Gateway's outside IP address"
}

variable "vpn_tunnel1_pre_shared_key" {
  description = "Shared secret used to set the secure session between the Cloud VPN gateway and the peer VPN gateway"
}

variable "vpn_tunnel2_name" {
  description = "The VPN tunnel #2 name"
}

variable "vpn_tunnel2_peer_ip" {
  description = "IP address of the peer VPN gateway. On AWS is Virtual Private Gateway's outside IP address"
}

variable "vpn_tunnel2_pre_shared_key" {
  description = "Shared secret used to set the secure session between the Cloud VPN gateway and the peer VPN gateway"
}

variable "remote_network_cidr" {
  description = "Remote network IP ranges"
}