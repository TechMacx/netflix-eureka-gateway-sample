## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}
variable "cluster_name" {}

## modues variables for VPC mapper
variable "vpc_id" {}             // Used in ECS tasks & service deployment
variable "vpc_cidr" {}           // Used in Security Group (ECS tasks) ingress rule 
variable "aws_subnet_public" {}  // Used in ALB subnet mapper
variable "aws_subnet_private" {} // Used in "aws_ecs_service" for walletapp & adminapp
variable "ecs_cluster_name" {}   // Used in ecs auto scaling part
variable "ecs_cluster_id" {}     // Used in "aws_ecs_service" for walletapp & adminapp
variable "public_dns_zone" {}    // used to create Alias "A" record for WalletApp
variable "acm_arn" {}            // used in ALB https listner

# ALB exposed port
variable "alb_http_port" {}     // Used in ALB security group (external exposed rules)
variable "alb_https_port" {}    // Used in ALB security group (external exposed rules)
variable "health_check_path" {} // used in ALB target_group

# common ecs tasks variables
variable "aws_region" {} // Used in template file for tasks defination

## Load Balancer Access log to S3 bucket 
variable "alb_accesslog_prefix" {} // ALB access log prefix
variable "elb_account_id" {}
variable "aws_account_id" {}

# adminapp ecs tasks variables
variable "adminapp_image" {} // Image source for Admin App source Image
variable "adminapp_desired_count" {}
variable "adminapp_fargate_cpu" {}
variable "adminapp_fargate_memory" {}
variable "adminapp_frontend_app_port" {}
variable "adminapp_scale_min_capacity" {}
variable "adminapp_scale_max_capacity" {}

# adminapp ecs tasks variables
variable "walletapp_image" {} // Image source for Client App source Image
variable "walletapp_desired_count" {}
variable "walletapp_fargate_cpu" {}
variable "walletapp_fargate_memory" {}
variable "walletapp_frontend_app_port" {}
variable "walletapp_scale_min_capacity" {}
variable "walletapp_scale_max_capacity" {}