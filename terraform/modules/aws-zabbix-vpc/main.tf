/* Define vpc */
resource "aws_vpc" "default" {
  cidr_block = "${var.aws_vpc_cidr}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.aws_subnet_cidr}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.default"]

  tags {
    Name = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "default_gw" {
  route_table_id            = "${aws_route_table.public.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.default.id}"
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_key_pair" "deployer" {
  // Only attempt to create the key pair if the public key was provided
  count = "${var.aws_public_key_path != "" ? 1 : 0}"

  key_name   = "${var.aws_key_name}"
  public_key = "${file("${var.aws_public_key_path}")}"
}

# Firewall
resource "aws_security_group" "zabbix_elk_ports" {
  name        = "${var.name}"
  description = "Security group for rancher hosts in ${var.name} cluster"
  vpc_id      = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "zabbix_subnet" {
  type = "ingress"
  from_port = "0"
  to_port   = "0"
  protocol  = "-1"
  cidr_blocks = ["${var.aws_subnet_cidr}"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}

resource "aws_security_group_rule" "ssh" {
  type = "ingress"
  from_port = "22"  # SSH
  to_port   = "22"
  protocol  = "tcp"
  cidr_blocks = ["${var.local_public_ip}"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}

resource "aws_security_group_rule" "http" {
  type = "ingress"
  from_port = "80"  # HTTP
  to_port   = "80"
  protocol  = "tcp"
  cidr_blocks = ["${var.local_public_ip}"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}

resource "aws_security_group_rule" "https" {
  type = "ingress"
  from_port = "443" # HTTPS
  to_port   = "443"
  protocol  = "tcp"
  cidr_blocks = ["${var.local_public_ip}"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}

#resource "aws_security_group_rule" "zabbix_agent" {
#  type = "ingress"
#  from_port = "10051" # Agent
#  to_port   = "10051"
#  protocol  = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#
#  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
#}

#resource "aws_security_group_rule" "elasticsearch_9200" {
#  type = "ingress"
#  from_port = "9200"  # Elastic Stack: Elasticsearch JSON interface
#  to_port   = "9200"
#  protocol  = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#
#  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
#}

#resource "aws_security_group_rule" "elasticsearch_9300" {
#  type = "ingress"
#  from_port = "9300"  # Elastic Stack: Elasticsearch transport interface
#  to_port   = "9300"
#  protocol  = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#
#  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
#}

resource "aws_security_group_rule" "elasticsearch_5601" {
  type = "ingress"
  from_port = "5601"  # Elastic Stack: Kibana web interface
  to_port   = "5601"
  protocol  = "tcp"
  cidr_blocks = ["${var.local_public_ip}"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}

resource "aws_security_group_rule" "out" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.zabbix_elk_ports.id}"
}
