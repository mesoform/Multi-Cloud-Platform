variable "hostname" {
  description = "zabbix-server"
}

variable "docker_engine_install_url" {
  default     = "https://get.docker.com"
  description = "The URL to the shell script to install the docker engine."
}

variable "aws_ami_id" {
  description = "Base AMI to launch the instances with"
}

variable "aws_instance_type" {
  default     = "t2.micro"
  description = "The AWS instance type to use for Kubernetes compute node(s). Defaults to t2.micro."
}

variable "aws_subnet_id" {
  description = "The AWS subnet id to deploy the instance to."
}

variable "aws_security_group_id" {
  description = "The AWS subnet id to deploy the instance to."
}

variable "aws_key_name" {
  description = "The AWS key name to use to deploy the instance."
}

variable "ebs_volume_device_name" {
  default     = ""
  description = "The EBS Device name"
}

variable "ebs_volume_mount_path" {
  default     = "/mnt/zabbix"
  description = "The EBS volume mount path"
}

variable "ebs_volume_type" {
  default     = "standard"
  description = "The EBS volume type. This can be gp2 for General Purpose SSD, io1 for Provisioned IOPS SSD, st1 for Throughput Optimized HDD, sc1 for Cold HDD, or standard for Magnetic volumes."
}

variable "ebs_volume_size" {
  default     = ""
  description = "The size of the volume, in GiBs."
}

variable "zabbix_server_image" {
  default     = "zabbix/zabbix-appliance:ubuntu-4.2.1"
  description = "The Zabbix server image to use."
}

variable "elasticsearch_image" {
  default = "docker.elastic.co/elasticsearch/elasticsearch:7.8.0"
  description = "The Elasticsearch docker image."
}

variable "elk_private_ip" {}
