variable "name" {
//  default = "aws-zabbix-vpn-cgw01"
  description = "The customers gateway tag Name"
}

variable "bgp_asn" {
  default = "65000"
  description = "The gateway's Border Gateway Protocol (BGP) Autonomous System Number (ASN)"
}

variable "ip_address" {
  description = "Required argument. IP of cgw external interface"
}

variable "type" {
  default = "ipsec.1"
}
