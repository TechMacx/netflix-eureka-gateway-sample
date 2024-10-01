# vpc variables.tf
variable "az_count" {}
variable "vpc_cidr" {}
variable "subnet_cidr_block" {}

## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## NAT instance
variable "keypair_name" {}
variable "nat_ami_id" {}
variable "instance_type" {}