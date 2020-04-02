output "gcp_vpn_ip" {
  value = "${google_compute_address.gcp_static_address.address}"
}

output "gcp_vpn_ip_name" {
  value = "${google_compute_address.gcp_static_address.name}"
}