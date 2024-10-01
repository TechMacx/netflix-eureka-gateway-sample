## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## variables for vpc mapper;
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "rds_subnet_group" {}

## variables used in secretmanager-secret stack for PostgreSQL databases;
# variable "db_identifier_name" {}
variable "db_engine" {}
variable "db_port" {}
# variable "db_username" {}
# variable "db_password" {} # randamiser_call by secret manager
# variable "db_name" {}

## variables used in rds-master stack for PostgreSQL databases;
variable "db_version" {}
variable "db_param_group" {}
variable "db_instance_class" {}
variable "db_alloc_storage" {}
variable "db_max_alloc_storage" {}
