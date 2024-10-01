## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## vars for api integration with load balancers 
variable "backend_nlb_arn" {} // used in api gateway VPC links (../ecs/ecs_backend_svc/nlb.tf)