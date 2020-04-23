variable "vgw_id" {}

variable "cgw_id" {}

variable "type" {
  default = "ipsec.1"
}

variable "static" {}

variable "gcp_vpc_cidr" {}