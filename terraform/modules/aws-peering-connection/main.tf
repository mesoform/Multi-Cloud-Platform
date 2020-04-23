resource "aws_vpc_peering_connection" "pc" {
  peer_vpc_id   = "${var.peer_vpc_id}"
  vpc_id        = "${var.vpc_id}"
  auto_accept   = true

  tags = {
    Name = "${var.name}"
  }
}
