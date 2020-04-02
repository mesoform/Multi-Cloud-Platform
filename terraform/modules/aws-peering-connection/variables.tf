variable "name" {
  description = "Value for the Name tag"
}

variable "peer_vpc_id" {
  description = "The ID of the VPC with which you are creating the VPC Peering Connection"
}

variable "vpc_id" {
  description = "The ID of the requester VPC"
}