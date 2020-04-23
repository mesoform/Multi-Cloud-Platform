output "aws_vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "aws_subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "aws_rt_id" {
  value = "${aws_route_table.public.id}"
}

output "aws_security_group_id" {
  value = "${aws_security_group.zabbix_elk_ports.id}"
}

output "aws_key_name" {
  value = "${var.aws_key_name}"
}
