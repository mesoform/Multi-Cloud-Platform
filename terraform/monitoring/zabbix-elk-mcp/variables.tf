variable "name" {
  description = "Human readable name used as prefix to generated names."
}

variable "docker_engine_install_url" {
  default     = "https://raw.githubusercontent.com/mesoform/triton-kubernetes/master/scripts/docker/17.03.sh"
  description = "The URL to the shell script to install the docker engine."
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret access key"
}

variable "aws_region" {
  description = "AWS region to host your network"
}

variable "aws_vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.64.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR for subnet"
  default     = "10.64.2.0/24"
}

variable "aws_ami_id" {
  description = "Base AMI to launch the instances with"
}

variable "aws_instance_type" {
  default     = "t2.micro"
  description = "The AWS instance type to use for Kubernetes compute node(s). Defaults to t2.micro."
}

variable "aws_key_name" {
  description = "The AWS key name to use to deploy the instance."
}

variable "aws_public_key_path" {
  description = "Path to a public key. If set, a key_pair will be made in AWS named aws_key_name"
  default     = "~/.ssh/id_rsa.pub"
}

variable "aws_private_key_path" {
  description = "Path to a private key."
  default     = "~/.ssh/id_rsa"
}

variable "aws_ssh_user" {
  default     = "ubuntu"
  description = "The ssh user to use."
}

variable "ebs_volume_device_name" {
  default = "/dev/sdf"
}

variable "ebs_volume_mount_path" {
  default = "/mnt/zabbix"
}

variable "ebs_volume_type" {
  default = "standard"
}

variable "ebs_volume_size" {
  default = "10"
}

variable "gcp_path_to_credentials" {
  default = "~/.ssh/gcp-account.json"
  description = "Path to gcp service account key file"
}

# Peering VPC info
variable "aws_k8s_cluster_name" {
  description = "Kubernetes cluster name which should be monitored"
}

variable "aws_peer_vpc_cidr" {
  description = "Kubernetes cluster VPC CIDR"
  default = "172.22.0.0/16"
}

variable "aws_peer_subnet_cidr" {
  description = "Kubernetes cluster subnet CIDR"
  default = "172.22.1.0/24"
}

variable "gcp_project_id" {}

variable "gcp_compute_region" {
  default = "us-east1"
  description = "Default gcp region to manage resources in"
}

variable "gcp_vpc_cidr" {
  description = "CIDR for subnet"
  default     = "10.128.0.0/9"
}

variable "gcp_external_ip_name" {
  description = "The GCP VPN External IP address name"
  default = "gcp-zabbix-vpn-ip"
}

variable "gcp_k8s_cluster_name" {
  description = "GCP Nework name, where Zabbix agents are deployed"
  default = "mcp-gcp-cluster"
}

variable "local_public_ip" {}

variable "secure_source_ip" {}