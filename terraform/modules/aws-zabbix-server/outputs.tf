output "aws_key_name" {
  value = "${var.aws_key_name}"
}

output "zabbix_aws_instance_id" {
  value = "${aws_instance.host.id}"
}

output "zabbix_aws_private_ip" {
  value = "${aws_instance.host.private_ip}"
}

output "zabbix_aws_public_ip" {
  value = "${aws_instance.host.public_ip}"
}
