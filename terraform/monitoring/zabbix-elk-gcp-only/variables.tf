variable "name" {
  description = "Human readable name used as prefix to generated names."
}

variable "docker_engine_install_url" {
  default     = "https://raw.githubusercontent.com/mesoform/triton-kubernetes/master/scripts/docker/17.03.sh"
  description = "The URL to the shell script to install the docker engine."
}

variable "gcp_credentials_path" {
  description = "Path to gcp service account key file"
}

variable "gcp_project_id" {}

variable "gcp_default_region" {}

variable "gcp_compute_region" {
  default = "europe-west2"
  description = "Default gcp region to manage resources in"
}

variable "gcp_instance_zone" {
  default = "europe-west2-b"
  description = "The zone of the instance. E.g. europe-west2-b"
}

variable "gcp_image" {
  default = "ubuntu-1604-xenial-v20190430"
  description = "The image to initialise the disk for instance. E.g. ubuntu-1604-xenial-v20190430"
}

//variable "gcp_vpc_cidr" {
//  description = "CIDR for subnet"
//  default     = "10.128.0.0/9"
//}
//
//variable "gcp_external_ip_name" {
//  default = "gcp-zabbix-vpn-ip"
//  description = "The GCP VPN External IP address name"
//}

variable "gcp_k8s_cluster_name" {
  description = "GCP Nework name, where Zabbix agents are deployed"
}

variable "gcp_volume_device_name" {}

variable "gcp_ssh_user" {}

variable "gcp_public_key_path" {}

variable "local_public_ip" {}