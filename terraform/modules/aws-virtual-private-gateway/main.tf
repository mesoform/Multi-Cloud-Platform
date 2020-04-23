/* Define virtual private gateway */

resource "aws_vpn_gateway" "aws_zabbix_vgw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "${var.name}"
  }
}
