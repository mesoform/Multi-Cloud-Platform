output "elk_gcp_private_ip" {
  value = "${google_compute_instance.elk_server.network_interface.0.network_ip}"
}
