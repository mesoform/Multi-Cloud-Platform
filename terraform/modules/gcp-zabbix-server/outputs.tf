output "zabbix_gcp_private_ip" {
  value = "${google_compute_instance.zabbix_server.network_interface.0.network_ip}"
}

output "zabbix_gcp_public_ip" {
  value = "${google_compute_instance.zabbix_server.network_interface.0.access_config.0.nat_ip}"
}
