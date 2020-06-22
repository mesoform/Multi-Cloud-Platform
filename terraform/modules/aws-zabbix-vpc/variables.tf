variable "name" {
  description = "Human readable name."
}

variable "aws_vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.64.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR for subnet"
  default     = "10.64.2.0/24"
}

variable "aws_key_name" {
  description = "Name of the public key to be used for provisioning"
}

variable "aws_public_key_path" {
  description = "Path to a public key. If set, a key_pair will be made in AWS named aws_key_name"
  default     = ""
}

variable "local_public_ip" {}

variable "secure_source_ip" {}
