## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}
variable "cluster_name" {}

## variables for VPC mapper
variable "vpc_id" {}             // Used in ECS tasks & service deployment
variable "aws_subnet_private" {} //used in clientapp ecs service
variable "vpc_cidr" {}           // Used in Security Group (ECS tasks) ingress rule 

# NLB exposed port
variable "http_tcp_port" {}  // Used in NLB external exposed Listner ID ** this are actually TCP 80
variable "https_tls_port" {} // Used in NLB external exposed Listner ID ** this are actually TLS 443

## add DNS record to route53
variable "public_dns_zone" {} // Create Route53 "A" record (alias) of adminApp API (api_custom_domain_name)

## variable for SSL certificate manager
variable "acm_arn" {} // Used in NLB TLS listeners

## ecs common variables
variable "ecs_cluster_name" {} // Used in ecs auto scaling part
variable "ecs_cluster_id" {}   // Used in "aws_ecs_service" for RestApi-SVC
variable "aws_region" {}       // Used in template file for tasks defination

## ecs webhook task variables
variable "webhook_app_port" {}      //port that used by application
variable "webhook_desired_count" {} // Number of docker containers to run inside ECS cluster for HA it should be 2
variable "webhook_scale_min_capacity" {}
variable "webhook_scale_max_capacity" {}
variable "webhook_svc_image" {}   // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
variable "webhook_fargate_cpu" {} // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
variable "webhook_fargate_memory" {}  