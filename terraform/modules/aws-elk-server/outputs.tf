output "elk_aws_instance_id" {
  value = "${aws_instance.elk_host.id}"
}

output "elk_aws_private_ip" {
  value = "${aws_instance.elk_host.private_ip}"
}