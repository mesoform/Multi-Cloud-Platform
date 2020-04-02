/* Define customer gateway */
resource "aws_customer_gateway" "aws_zabbix_cgw" {
  bgp_asn    = "${var.bgp_asn}"
  ip_address = "${var.ip_address}"
  type       = "${var.type}"

  tags = {
    Name = "${var.name}"
  }
}