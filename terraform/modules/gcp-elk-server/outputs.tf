output "elk_gcp_private_ip" {
  value = "${google_compute_instance.elk_server.network_interface.0.network_ip}"
}

output "elk_gcp_public_ip" {
  value = "${google_compute_instance.elk_server.network_interface.0.access_config.0.nat_ip}"
}
