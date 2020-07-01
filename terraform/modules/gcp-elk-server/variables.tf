variable "hostname" {
  description = "elk-server"
}

variable "docker_engine_install_url" {
  default     = "https://get.docker.com"
  description = "The URL to the shell script to install the docker engine."
}

variable "gcp_volume_device_name" {
  description = "The device name. E.g. /dev/sdf"
}

variable "gcp_volume_mount_path" {
  default     = "/mnt/elk"
  description = "The volume mount path"
}

variable "elasticsearch_image" {
  default = "docker.elastic.co/elasticsearch/elasticsearch:7.8.0"
  description = "The Elasticsearch docker image."
}

variable "gcp_machine_type" {
  default = "e2-medium"
  description = "The machine type to create"
}

variable "gcp_instance_zone" {
  description = "The zone of the instance. E.g. us-east1-b"
}

variable "gcp_project_id" {}

variable "gcp_service_account_email" {
  description = "Service account client email"
}

variable "gcp_image" {
  description = "The image to initialise the disk for instance. E.g. ubuntu-1604-xenial-v20190430"
}

variable "gcp_compute_region" {
  description = "Default gcp region to manage resources in"
//  default = "us-east1"
}

variable "gcp_compute_network_name" {
  description = "The name of the network attached to interface in this instance"
}

variable "gcp_compute_subnetwork_name" {
  description = "The name of the subnetwork attached to interface in this instance"
}

variable "gcp_ssh_user" {}

variable "gcp_public_key_path" {}

variable "gcp_disk_type" {
  default = "pd-ssd"
  description = "The GCE disk type. One of pd-standard or pd-ssd"
}

variable "gcp_disk_size" {
  default = "20"
  description = "The size of the image in gigabytes"
}

variable "mcp_topic_name" {}

variable "mcp_subscription_name" {}
