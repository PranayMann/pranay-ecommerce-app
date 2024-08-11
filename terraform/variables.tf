variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "ap-south-1"
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "eks-key"
}

data "aws_availability_zones" "available" {}