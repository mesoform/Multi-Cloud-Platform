# Define outputs
output "zabbix_private_ip" {
  value = "${module.zabbix_server.zabbix_gcp_private_ip}"
}

output "elk_private_ip" {
  value = "${module.elk_server.elk_gcp_private_ip}"
}
