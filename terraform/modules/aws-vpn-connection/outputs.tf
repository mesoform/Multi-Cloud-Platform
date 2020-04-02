output "vpn_connection_id" {
  value = "${aws_vpn_connection.s2s_vpn.id}"
}

output "t1_address" {
  value = "${aws_vpn_connection.s2s_vpn.tunnel1_address}"
}

output "t1_key" {
  value = "${aws_vpn_connection.s2s_vpn.tunnel1_preshared_key}"
}

output "t2_address" {
  value = "${aws_vpn_connection.s2s_vpn.tunnel2_address}"
}

output "t2_key" {
  value = "${aws_vpn_connection.s2s_vpn.tunnel2_preshared_key}"
}
