## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## variables for vpc mapper;
variable "vpc_id" {}

## subnet id to launch vm
variable "ovpn_subnet_ids" {}
variable "current_vpc_igw" {}
variable "keypair_name" {}

## AMI ID 
variable "ami_id" {}
variable "instance_type" {}