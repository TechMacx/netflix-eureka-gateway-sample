## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}
variable "cluster_name" {}

## variables for VPC mapper
variable "vpc_id" {}             // Used in ECS tasks & service deployment
variable "aws_subnet_private" {} //used in clientapp ecs service
variable "vpc_cidr" {}           // Used in Security Group (ECS tasks) ingress rule 

## variable for SSL certificate manager
variable "acm_arn" {} // Used in NLB TLS listeners

## ecs common variables
variable "ecs_cluster_name" {} // Used in ecs auto scaling part
variable "ecs_cluster_id" {}   // Used in "aws_ecs_service" for RestApi-SVC
variable "aws_region" {}       // Used in template file for tasks defination

## Load Balancer Access log to S3 bucket 
variable "nlb_accesslog_prefix" {} // NLB access log prefix

variable "elb_account_id" {}
variable "aws_account_id" {}

## ecs restapi task variables
# # nlb exposed port  (currently not used for restapi service)
# variable "http_tcp_port" {}  // Used in NLB external exposed Listner ID ** this are actually TCP 80
# variable "https_tls_port" {} // Used in NLB external exposed Listner ID ** this are actually TLS 443
variable "restapi_app_port" {}
variable "restapi_desired_count" {}
variable "restapi_scale_min_capacity" {}
variable "restapi_scale_max_capacity" {}
variable "restapi_svc_image" {} // Image source for RestApi-SVC source Image
variable "restapi_fargate_cpu" {}
variable "restapi_fargate_memory" {}


## ecs healthapi task variables
variable "healthapi_app_port" {}      //port that used by application
variable "healthapi_desired_count" {} // Number of docker containers to run inside ECS cluster for HA it should be 2
variable "healthapi_scale_min_capacity" {}
variable "healthapi_scale_max_capacity" {}
variable "healthapi_svc_image" {}   // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
variable "healthapi_fargate_cpu" {} // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
variable "healthapi_fargate_memory" {}


## ecs Webhook task variables
variable "webhook_app_port" {}
variable "webhook_desired_count" {}
variable "webhook_scale_min_capacity" {}
variable "webhook_scale_max_capacity" {}
variable "webhook_svc_image" {} // Image source for RestApi-SVC source Image
variable "webhook_fargate_cpu" {}
variable "webhook_fargate_memory" {}