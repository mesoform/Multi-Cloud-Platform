/* Setup aws provider */
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

/* Setup google provider */
provider "google" {
  credentials = "${file("${var.gcp_path_to_credentials}")}"
  project     = "${var.gcp_project_id}"
  region      = "${var.gcp_compute_region}"
}

## Zabbix to GCP Kubernetes cluster

module "gcp_zabbix_vpn_ip" {
  source = "../../modules/gcp-vpn-address"

  name        = "${var.gcp_external_ip_name}"
  project_id  = "${var.gcp_project_id}"
  region      = "${var.gcp_compute_region}"
}

module "aws_zabbix_customer_gateway" {
  source = "../../modules/aws-customer-gateway"

  name        = "aws-zabbix-vpn-cgw01"
  ip_address  = "${module.gcp_zabbix_vpn_ip.gcp_vpn_ip}"
}

module "zabbix_elk_vpc" {
  source = "../../modules/aws-zabbix-vpc"

  name                = "zabbix-vpc"
  aws_vpc_cidr        = "${var.aws_vpc_cidr}"
  aws_subnet_cidr     = "${var.aws_subnet_cidr}"
  aws_key_name        = "${var.aws_key_name}"
  aws_public_key_path = "${var.aws_public_key_path}"
  local_public_ip      = "${var.local_public_ip}"
}

module "aws_zabbix_virtual_private_gateway" {
  source = "../../modules/aws-virtual-private-gateway"

  name    = "aws-zabbix-vpn-vgw01"
  vpc_id  = "${module.zabbix_elk_vpc.aws_vpc_id}"
}

# Enable route propagation
resource "aws_vpn_gateway_route_propagation" "aws_route_propagation" {
  vpn_gateway_id = "${module.aws_zabbix_virtual_private_gateway.vgw_id}"
  route_table_id = "${module.zabbix_elk_vpc.aws_rt_id}"
}

# Add route to the gcp vpc through vpn
resource "aws_route" "route_to_gcp_vpc" {
  route_table_id          = "${module.zabbix_elk_vpc.aws_rt_id}"
  destination_cidr_block  = "${var.gcp_vpc_cidr}"
  gateway_id              = "${module.aws_zabbix_virtual_private_gateway.vgw_id}"
}

module "aws_zabbix_vpn" {
  source = "../../modules/aws-vpn-connection"

  cgw_id        = "${module.aws_zabbix_customer_gateway.cgw_id}"
  vgw_id        = "${module.aws_zabbix_virtual_private_gateway.vgw_id}"
  static        = "true"
  gcp_vpc_cidr  = "${var.gcp_vpc_cidr}"
}

module "gcp_zabbix_vpn" {
  source      = "../../modules/gcp-vpn-connection"
  name        = "gcp-zabbix-vpn01"
  project_id  = "${var.gcp_project_id}"
  region      = "${var.gcp_compute_region}"

  remote_network_cidr         = "${var.aws_subnet_cidr}"
  vpn_network_name            = "${var.gcp_k8s_cluster_name}"
  vpn_static_ip_name          = "${module.gcp_zabbix_vpn_ip.gcp_vpn_ip_name}"
  vpn_tunnel1_name            = "gcp-tunnel1"
  vpn_tunnel1_peer_ip         = "${module.aws_zabbix_vpn.t1_address}"
  vpn_tunnel1_pre_shared_key  = "${module.aws_zabbix_vpn.t1_key}"
  vpn_tunnel2_name            = "gcp-tunnel2"
  vpn_tunnel2_peer_ip         = "${module.aws_zabbix_vpn.t2_address}"
  vpn_tunnel2_pre_shared_key  = "${module.aws_zabbix_vpn.t2_key}"
}

## Zabbxi to AWS Kubernetes cluster

# AWS Kubernetes cluster data sources
# AWS Kubernetes cluster VPC
data "aws_vpc" "cluster" {
  cidr_block = "${var.aws_peer_vpc_cidr}"

  tags {
    Name = "${var.aws_k8s_cluster_name}"
  }
}

# Subnet where Kubernetes cluster instanses are created
data "aws_subnet" "subnet_cluster01" {
  cidr_block = "${var.aws_peer_subnet_cidr}"
  vpc_id = "${data.aws_vpc.cluster.id}"
}

# Route table on Kubernetes cluster side
data "aws_route_table" "rt_cluster01" {
  vpc_id = "${data.aws_vpc.cluster.id}"
  subnet_id = "${data.aws_subnet.subnet_cluster01.id}"
}

# Security group assossiated with Kubernetes cluster's VPCide

data "aws_security_group" "sg_cluster01" {
  name = "${var.aws_k8s_cluster_name}"
  vpc_id = "${data.aws_vpc.cluster.id}"
}

module "aws_peering" {
  source = "../../modules/aws-peering-connection"
  name = "zabbix-peering-connection"
  peer_vpc_id = "${data.aws_vpc.cluster.id}"
  vpc_id = "${module.zabbix_elk_vpc.aws_vpc_id}"
}

# Add route to Zabbix server from Kubernetes cluster
resource "aws_route" "route_from_cluster01" {
  route_table_id          = "${data.aws_route_table.rt_cluster01.id}"
  destination_cidr_block  = "${var.aws_subnet_cidr}"
  vpc_peering_connection_id = "${module.aws_peering.pc_id}"
}

# Add route to the peering vpc (Kubernetes cluster)
resource "aws_route" "route_to_peering_vpc" {
  route_table_id          = "${module.zabbix_elk_vpc.aws_rt_id}"
  destination_cidr_block  = "${var.aws_peer_subnet_cidr}"
  vpc_peering_connection_id = "${module.aws_peering.pc_id}"
}

# Add rules to security goups
resource "aws_security_group_rule" "allow_from_cluster" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"

  security_group_id = "${module.zabbix_elk_vpc.aws_security_group_id}"
  source_security_group_id = "${data.aws_security_group.sg_cluster01.id}"
}

resource "aws_security_group_rule" "allow_from_zabbix_server" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = "${data.aws_security_group.sg_cluster01.id}"
  source_security_group_id = "${module.zabbix_elk_vpc.aws_security_group_id}"
}

resource "aws_security_group_rule" "allow_from_gcp_cluster" {
  type = "ingress"
  from_port = "0"
  to_port   = "0"
  protocol  = "-1"
  cidr_blocks = ["${var.gcp_vpc_cidr}"]

  security_group_id = "${module.zabbix_elk_vpc.aws_security_group_id}"
}

## ELK server on AWS
module "elk_server" {
  source = "../../modules/aws-elk-server"

  hostname                = "elk-server"
  aws_ami_id              = "${var.aws_ami_id}"
  aws_key_name            = "${module.zabbix_elk_vpc.aws_key_name}"
  aws_security_group_id   = "${module.zabbix_elk_vpc.aws_security_group_id}"
  aws_subnet_id           = "${module.zabbix_elk_vpc.aws_subnet_id}"
  ebs_volume_device_name  = "${var.ebs_volume_device_name}"
  ebs_volume_type         = "${var.ebs_volume_type}"
  ebs_volume_size         = "${var.ebs_volume_size}"
}

## Zabbix server on AWS
module "zabbix_server" {
  source = "../../modules/aws-zabbix-server"

  hostname                = "zabbix-server"
  aws_ami_id              = "${var.aws_ami_id}"
  aws_instance_type       = "${var.aws_instance_type}"
  aws_key_name            = "${module.zabbix_elk_vpc.aws_key_name}"
  aws_security_group_id   = "${module.zabbix_elk_vpc.aws_security_group_id}"
  aws_subnet_id           = "${module.zabbix_elk_vpc.aws_subnet_id}"
  ebs_volume_device_name  = "${var.ebs_volume_device_name}"
  ebs_volume_mount_path   = "${var.ebs_volume_mount_path}"
  ebs_volume_type         = "${var.ebs_volume_type}"
  ebs_volume_size         = "${var.ebs_volume_size}"
  elk_private_ip          = "${module.elk_server.elk_aws_private_ip}"
}

## Setup zabbix agents on both clusters (AWS and GCP)
module "kubernetes_daemonset_zabbix_aws" {
  source = "../../modules/k8s-zabbix-agent-daemonset"

  kube_config_path = "~/.kube/config.aws"
  zbxsrv_private_ip = "${module.zabbix_server.zabbix_aws_private_ip}"
  zbxsrv_public_ip = "${module.zabbix_server.zabbix_aws_public_ip}"
}

module "kubernetes_daemonset_zabbix_gcp" {
  source = "../../modules/k8s-zabbix-agent-daemonset"

  kube_config_path = "~/.kube/config.gcp"
  zbxsrv_private_ip = "${module.zabbix_server.zabbix_aws_private_ip}"
  zbxsrv_public_ip = "${module.zabbix_server.zabbix_aws_public_ip}"
}

## Setup elk filebeats on both clusters (AWS and GCP)
module "kubernetes_daemonset_elk_aws" {
  source = "../../modules/k8s-elk-filebeat-daemonset"

  kube_config_path = "~/.kube/config.aws"
  elksrv_private_ip = "${module.elk_server.elk_aws_private_ip}"
  elksrv_public_ip = "${module.elk_server.elk_aws_public_ip}"
  k8s_cluster_name = "${var.aws_k8s_cluster_name}"
}

module "kubernetes_daemonset_elk_gcp" {
  source = "../../modules/k8s-elk-filebeat-daemonset"

  kube_config_path = "~/.kube/config.gcp"
  elksrv_private_ip = "${module.elk_server.elk_aws_private_ip}"
  elksrv_public_ip = "${module.elk_server.elk_aws_public_ip}"
  k8s_cluster_name = "${var.gcp_k8s_cluster_name}"
}
