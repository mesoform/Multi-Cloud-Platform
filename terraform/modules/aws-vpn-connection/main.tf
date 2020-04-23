resource "aws_vpn_connection" "s2s_vpn" {
  vpn_gateway_id      = "${var.vgw_id}"
  customer_gateway_id = "${var.cgw_id}"
  type                = "${var.type}"
  static_routes_only  = "${var.static}"
}

resource "aws_vpn_connection_route" "gcp_vpc" {
  destination_cidr_block = "${var.gcp_vpc_cidr}"
  vpn_connection_id      = "${aws_vpn_connection.s2s_vpn.id}"
}