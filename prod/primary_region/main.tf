#####################################################################################
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
############################      COMMON OPTPUT      ################################
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#####################################################################################

## collect AWS account informations
module "aws_account_info" {
  source = "./module_aws_account"
  ## we can define veriable inside moudles, this can overide veriables value
}


# #####################################################################################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ###############################       PHASE - I       ###############################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# #####################################################################################

##--------------------------------------------
## DNS Module [create Primary DNS Name Server]
##--------------------------------------------
# module "public_zone" {
#   source = "./modules/route53_public_zone"
#   ## we can define veriable inside moudles, this can overide veriables value
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
# }

// OR //

module "public_zone" {
  source = "./modules/route53_public_zone_existing"
  ## we can define veriable inside moudles, this can overide veriables value
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  zone_id     = "Z02394041YB08U8BWW355" // Provide existing zone id
}

##------------------------------------------------------------------
## ECR module [create private Repository to store all Docker Images]
##------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
}

// OR // 

# module "ecr" {
#   source = "./modules/ecr_existing"
#   ## we can define veriable inside moudles, this can overide veriables value
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name

#   ## existing repositorys
#   frontend-adminapp   = "uat-nuestro-frontend-adminapp"
#   frontend-walletapp  = "uat-nuestro-frontend-walletapp"
#   backend-restapi-svc = "uat-nuestro-restapi-svc"
#   backend-health-svc  = "uat-nuestro-health-svc"
#   backend-webhook-svc = "uat-nuestro-webhook-svc"
# }

#--------------------------------------------------------------------------
# Generate RSA Keypair [create keypair for SSH into VMs (e.g. keypair.pem)]
#--------------------------------------------------------------------------
module "ssh-keypair" {
  source = "./modules/ssh-keypair"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
}

# #####################################################################################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ##############################       PHASE - II        ##############################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# #####################################################################################

##-----------------------------------------------------------------
## Certificate Manager Module [create SSL certs and DNS validation]
##-----------------------------------------------------------------
module "acm" {
  source = "./modules/acm"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
}

##------------------------------------------
## VPC Module [create Virtual private cloud]
##-----------------------------------------
module "vpc" {
  source = "./modules/vpc-prod"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## VPC parameeters
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
  subnet_cidr_block = var.subnet_cidr_block

}

// OR //

# module "vpc" {  
#   source = "./modules/vpc-dev"
#   ## we can define veriable inside moudles, this can overide veriables value
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
#   ## VPC parameeters
#   az_count          = var.az_count
#   vpc_cidr          = var.vpc_cidr
#   subnet_cidr_block = var.subnet_cidr_block
#   ## define NAT Instance 
#   nat_ami_id    = "ami-0c65039d08fea77c7" 
#   keypair_name  = module.ssh-keypair.keypair_name
#   instance_type = "t3a.micro"
#   depends_on    = [module.ssh-keypair] // used in NAT instance to provide SSH Keypair

# }

##--------------------------------------------
## DNS Module [create Private DNS Name Server]
##--------------------------------------------
module "private_zone" {
  source = "./modules/route53_private_zone"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  vpc_id      = module.vpc.vpc_id //get the vpc ID from module "modules/vpc
}

// OR //

# module "private_zone" {
#   source = "./modules/route53_private_zone_existing"
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
#   vpc_id      = module.vpc.vpc_id       //get the vpc ID from module "modules/vpc
#   zone_id     = "Z06387363SZ3ZGNJITUG8" // prodive existing zone id
# }

# ##--------------------------------------------------------------------------------
# ## Install OpenVPN apps [create VPN instance to access all EC2/RDS VMs inside VPC]
# ##--------------------------------------------------------------------------------
module "ovpn-vm" {
  source = "./modules/ovpn-vm"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## module vars
  vpc_id          = module.vpc.vpc_id
  ovpn_subnet_ids = module.vpc.aws_subnet_public
  current_vpc_igw = module.vpc.current_vpc_igw
  keypair_name    = module.ssh-keypair.keypair_name
  ami_id          = "ami-0f95ee6f985388d58" // Provide AMI for for specific Region 
  instance_type   = "t3a.micro"
}

##-------------------------------------------------------------------------------------------------
## RDS module / Secret Manager / RDS-SG [create RDS postgres DB and Keep secrets to Secret Manager]
##-------------------------------------------------------------------------------------------------
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster

module "rds_secruty_group" {
  source = "./modules/rds/rds_security_group"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## VPC modules veriable
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  ## DB Port
  db_port = "3306" // replace postgres port number for postgres db_engine

}

## RDS MYSQL database
## ------------------
module "rds" {
  source = "./modules/rds/mysql"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## VPC modules veriable
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = module.vpc.vpc_cidr
  rds_subnet_group  = module.vpc.rds_subnet_group // module.vpc.aws_subnet_isolated
  rds_secruty_group = module.rds_secruty_group.database_secruty_group
  #DB variables
  db_port              = "3306"
  db_alloc_storage     = "10"
  db_max_alloc_storage = "20"
  db_version           = "5.7"
  db_engine            = "mysql"
  db_param_group       = "default.mysql5.7"
  db_instance_class    = "db.t3.medium"
}


# module "rds" {
#   source = "./modules/rds/postgres"
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
#   ## VPC modules veriable
#   vpc_id           = module.vpc.vpc_id
#   vpc_cidr         = module.vpc.vpc_cidr
#   rds_subnet_group = module.vpc.aws_subnet_isolated
#   #DB variables
#   db_port              = "5432"
#   db_alloc_storage     = "10"
#   db_max_alloc_storage = "20"
#   db_version           = "14.3"
#   db_engine            = "postgres"
#   db_param_group       = "default.postgres14"
#   db_instance_class    = "db.t3.micro"
#   // db_identifier_name = var.db_identifier_name
#   // db_major_version = "14.3"
# }


# #####################################################################################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ##############################       PHASE - III       ##############################
# //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# #####################################################################################

##-----------------------------------------------------------------------------
## ECS cluster module [create ECS fargate cluster & run ecs tasks and services]
##-----------------------------------------------------------------------------
module "ecs" {
  source = "./modules/ecs"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
}

# # ECS frontend application module
# #################################
# module "ecs_frontend_apps" {
#   source = "./modules/ecs/ecs_frontend_apps"
#   # we can define veriable inside moudles, this can overide veriables value 
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
#   cluster_name = var.cluster_name

#   # Variables from modules
#   vpc_id             = module.vpc.vpc_id                  // Used in ECS tasks & service deployment
#   vpc_cidr           = module.vpc.vpc_cidr                // Used in Security Group (ECS tasks) ingress rule 
#   aws_subnet_public  = module.vpc.aws_subnet_public       // Used in ALB subnet mapper
#   aws_subnet_private = module.vpc.aws_subnet_private      // Used in "aws_ecs_service" for walletapp & adminapp
#   ecs_cluster_name   = module.ecs.ecs_cluster_name        // Used in ecs auto scaling part
#   ecs_cluster_id     = module.ecs.ecs_cluster_id          // Used in "aws_ecs_service" for walletapp & adminapp
#   public_dns_zone    = module.public_zone.public_dns_zone // used to create Alias "A" record for walletapp
#   acm_arn            = module.acm.acm_arn                 // used in ALB https listner

#   # for ALB 
#   health_check_path = "/"
#   alb_http_port     = 80
#   alb_https_port    = 443

#   # common variables ECS tasks
#   aws_region = var.aws_region // Used in template file for tasks defination

#   ## used in s3 Access Logs configuration
#   alb_accesslog_prefix = "frontend-service-alb"
#   elb_account_id       = module.aws_account_info.elb_account_id // AWS ELB service account ID fetch
#   aws_account_id       = module.aws_account_info.aws_account_id // AWS account ID fetch

#   # AdminApp ECS tasks
#   adminapp_frontend_app_port  = 80
#   adminapp_desired_count      = 0 // Number of docker containers to run inside ECS cluster for HA it should be 2
#   adminapp_scale_min_capacity = 0
#   adminapp_scale_max_capacity = 8
#   adminapp_image              = module.ecr.adminapp_image // Get the Image from ecr module without tags
#   adminapp_fargate_cpu        = "256"                     // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
#   adminapp_fargate_memory     = "512"

#   # WalletApp ECS tasks
#   walletapp_frontend_app_port  = 80
#   walletapp_desired_count      = 0 // Number of docker containers to run inside ECS cluster for HA it should be 2
#   walletapp_scale_min_capacity = 0
#   walletapp_scale_max_capacity = 8
#   walletapp_image              = module.ecr.walletapp_image // Get the Image from ecr module without tags
#   walletapp_fargate_cpu        = "256"                      // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
#   walletapp_fargate_memory     = "512"

#   depends_on = [module.ecr, module.ecs, module.public_zone, module.acm]

# }

## ECS Backend restapi service module
## -----------------------------------
module "ecs_backend_svc" {
  source = "./modules/ecs/ecs_backend_svc"
  ## common vars
  infra_env    = var.infra_env
  proj_name    = var.proj_name
  domain_name  = var.domain_name
  cluster_name = var.cluster_name

  ## modules vars
  vpc_id             = module.vpc.vpc_id             // Used in ECS tasks & service deployment
  vpc_cidr           = module.vpc.vpc_cidr           // Used in Security Group (ECS tasks) ingress rule 
  aws_subnet_private = module.vpc.aws_subnet_private // Used in "aws_ecs_service" for walletapp & adminapp
  ecs_cluster_name   = module.ecs.ecs_cluster_name   // Used in ecs auto scaling part
  ecs_cluster_id     = module.ecs.ecs_cluster_id     // Used in "aws_ecs_service" for walletapp & adminapp
  acm_arn            = module.acm.acm_arn            // used in ALB https listner

  ## RestApi NLB & ECS task definations
  aws_region     = var.aws_region                         // Used in template file for tasks defination
  elb_account_id = module.aws_account_info.elb_account_id // AWS ELB service account ID fetch
  aws_account_id = module.aws_account_info.aws_account_id // AWS account ID fetch

  ## used in s3 Access Logs configuration
  nlb_accesslog_prefix = "restapi-service-nlb"

  ## RestApi NLB & ECS task definations
  # http_tcp_port      = "80"
  # https_tls_port     = "443"
  restapi_app_port           = "8080" //port that used by application
  restapi_desired_count      = 1      // Number of docker containers to run inside ECS cluster for HA it should be 2
  restapi_scale_min_capacity = 1
  restapi_scale_max_capacity = 16
  restapi_svc_image          = module.ecr.restapi_svc_image // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
  restapi_fargate_cpu        = "512"                        // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
  restapi_fargate_memory     = "1024"                       // Fargate instance memory to provision (in MiB)

  ## HealthService NLB & ECS task definations
  healthapi_app_port           = "8181" //port that used by application
  healthapi_desired_count      = 1      // Number of docker containers to run inside ECS cluster for HA it should be 2
  healthapi_scale_min_capacity = 1
  healthapi_scale_max_capacity = 4
  healthapi_svc_image          = module.ecr.healthapi_svc_image // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
  healthapi_fargate_cpu        = "256"                          // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
  healthapi_fargate_memory     = "512"                          // Fargate instance memory to provision (in MiB)

  ## WebhookService NLB & ECS task definations
  webhook_app_port           = "8000" //port that used by application
  webhook_desired_count      = 0      // Number of docker containers to run inside ECS cluster for HA it should be 2
  webhook_scale_min_capacity = 0
  webhook_scale_max_capacity = 8
  webhook_svc_image          = module.ecr.webhook_svc_image // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
  webhook_fargate_cpu        = "256"                        // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
  webhook_fargate_memory     = "512"                        // Fargate instance memory to provision (in MiB)

  depends_on = [module.ecr, module.ecs, module.public_zone, module.acm]
}

# # ## ECS WEBHOOK service module
# # ## --------------------------
# # module "ecs_webhook_svc" {
# #   source = "./modules/ecs/ecs_webhook_svc"
# #   ## common vars
# #   infra_env   = var.infra_env
# #   proj_name   = var.proj_name
# #   domain_name = var.domain_name
# #   cluster_name = var.cluster_name

# #   ## modules vars
# #   vpc_id             = module.vpc.vpc_id                  // Used in ECS tasks & service deployment
# #   vpc_cidr           = module.vpc.vpc_cidr                // Used in Security Group (ECS tasks) ingress rule 
# #   aws_subnet_private = module.vpc.aws_subnet_private      // Used in "aws_ecs_service" for WebhookService
# #   ecs_cluster_name   = module.ecs.ecs_cluster_name        // Used in ecs auto scaling part
# #   ecs_cluster_id     = module.ecs.ecs_cluster_id          // Used in "aws_ecs_service" for WebhookService
# #   public_dns_zone    = module.public_zone.public_dns_zone // used to create Alias "A" record for WebhookService  
# #   acm_arn            = module.acm.acm_arn                 // used in ALB https listner

# #   ## NLB & ECS task definations
# #   aws_region                 = var.aws_region // Used in template file for tasks defination
# #   http_tcp_port              = "80"
# #   https_tls_port             = "443"
# #   webhook_app_port           = "8080" //port that used by application
# #   webhook_desired_count      = 0      // Number of docker containers to run inside ECS cluster for HA it should be 2
# #   webhook_scale_min_capacity = 0
# #   webhook_scale_max_capacity = 8
# #   webhook_svc_image          = module.ecr.webhook_svc_image // Get the Image from ecr module without tags ("nginx:latest" // pull from docker hub)
# #   webhook_fargate_cpu        = "256"                        // Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)
# #   webhook_fargate_memory     = "512"                        // Fargate instance memory to provision (in MiB)

# #   depends_on = [module.ecr, module.ecs, module.public_zone, module.acm]

# # }

##---------------------------------------------
## API Gateway Module [used for API proxy call]
##---------------------------------------------

## Create a VPC link
##------------------
module "vpc_link" {
  source = "./modules/api_gateways/vpclink"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## vpc link mapped with load balancers 
  backend_nlb_arn = module.ecs_backend_svc.backend_nlb_arn // used in api gateway VPC links (../ecs/ecs_backend_svc/nlb.tf)
}

## Create a CloudWatch Api Gateway Account: [logging & monitoring]
##----------------------------------------
module "apigateway_account_cloudwatch" {
  source = "./modules/api_gateways/api_gateway_cloudwatch_account"
  ## common vars
  infra_env    = var.infra_env
  proj_name    = var.proj_name
  domain_name  = var.domain_name
  cluster_name = var.cluster_name
}

## Create a API gateway for healthApi
##-----------------------------------
module "healthcheck_api_gateway" {
  source = "./modules/api_gateways/api_healthcheck_svc"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## modules vars
  vpc_link_id     = module.vpc_link.vpc_link_id
  nlb_uri         = module.ecs_backend_svc.backend_nlb_hostname
  acm_arn         = module.acm.acm_arn                 // used in custom domain name (SSL) HTTPS listner 
  public_dns_zone = module.public_zone.public_dns_zone // used to create Alias "A" record for ClientApp
  ## create custom domain name for Healthcheck api
  health_api_gw_cdn = "${var.aws_region}-pri-healthcheck-api" // apigateway custom domain name
  ## failover_routing_settings.
  # clientapp_failover_dns_record = "healthcheck-api"
  aws_region = var.aws_region
}

# Create a API gateway for ClientApp
#-----------------------------------
module "clientapp_api_gateway" {
  source = "./modules/api_gateways/api_gateway_jwt"
  ## common vars
  infra_env    = var.infra_env
  proj_name    = var.proj_name
  domain_name  = var.domain_name
  cluster_name = var.cluster_name

  ## modules vars
  vpc_link_id     = module.vpc_link.vpc_link_id
  nlb_uri         = module.ecs_backend_svc.backend_nlb_hostname
  acm_arn         = module.acm.acm_arn                 // used in custom domain name (SSL) HTTPS listner 
  public_dns_zone = module.public_zone.public_dns_zone // used to create Alias "A" record for ClientApp
  ## calling jwt authorizer for clientapp
  clientapp_api_gw_cdn   = "${var.aws_region}-pri-payment-api" // apigateway custom domain name
  clientapp_jwtauth_name = "jwtRsaAuthClientApp"
  clientapp_jwks_uri     = "https://nuestro.us.auth0.com/.well-known/jwks.json" // The URL of the JWKS endpoint (to get the public keys used to sign the JWT) https://example.auth0.com/.well-known/jwks.json
  clientapp_token_issuer = "https://nuestro.us.auth0.com/"                      // The JWT issuing authority (to check the issuer inside the token) e.g. https://example.auth0.com
  audience               = "payment-api"
  ## failover_routing_settings.
  clientapp_failover_dns_record = "payment-api"
  aws_region                    = var.aws_region
  dns_healthcheck_url           = module.healthcheck_api_gateway.dns_healthcheck_url
  depends_on                    = [module.healthcheck_api_gateway]

  ## Lambda Logging and Monitoring
  // get the ARN for others region: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versionsx86-64.html
  lambda_insights_layers = "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:35"

}

# ## Create a API gateway for AdmintApp
# ## ----------------------------------
# module "adminapp_api_gateway" {
#   source = "./modules/api_gateways/api_gateway_cognito"
#   ## we can define veriable inside moudles, this can overide veriables value 
#   ## common vars
#   infra_env   = var.infra_env
#   proj_name   = var.proj_name
#   domain_name = var.domain_name
#   cluster_name = var.cluster_name
#   ## calling output variables from modules
#   vpc_link_id     = module.vpc_link.vpc_link_id
#   nlb_uri         = module.ecs_backend_svc.backend_nlb_hostname
#   acm_arn         = module.acm.acm_arn                 // used in custom domain name (SSL) HTTPS listner 
#   public_dns_zone = module.public_zone.public_dns_zone // used to create Alias "A" record for ClientApp
#   ## calling Cognito & Custom Domain Name DNS record for addminapp
#   adminapp_api_gw_cdn = "${var.aws_region}-pri-adminapp-api" // apigateway custom domain name
#   ses_email_addresses = var.ses_email_addresses              // Post Login scripts for Cognito EMAIL verification lambda_post_login.tf ;
#   ## failover_routing_settings. 
#   adminapp_failover_dns_record = "adminapp-api"
#   aws_region                   = var.aws_region
#   dns_healthcheck_url          = module.healthcheck_api_gateway.dns_healthcheck_url
#   depends_on                   = [module.healthcheck_api_gateway]
# }

## Create a API gateway for Webhook-Svc
##-------------------------------------
module "webhook_api_gateway" {
  source = "./modules/api_gateways/api_webhook_svc"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  ## modules vars
  vpc_link_id     = module.vpc_link.vpc_link_id
  nlb_uri         = module.ecs_backend_svc.backend_nlb_hostname
  acm_arn         = module.acm.acm_arn                 // used in custom domain name (SSL) HTTPS listner 
  public_dns_zone = module.public_zone.public_dns_zone // used to create Alias "A" record for ClientApp
  ## create custom domain name for webhookcheck api
  webhook_api_gw_cdn = "${var.aws_region}-pri-webhook-api" // apigateway custom domain name
  ## failover_routing_settings.
  webhook_failover_dns_record = "webhook-api"
  aws_region                  = var.aws_region
  dns_healthcheck_url         = module.healthcheck_api_gateway.dns_healthcheck_url
  depends_on                  = [module.healthcheck_api_gateway]
}

##------------------------------------
## S3 Bucket : API signed file updalod 
##------------------------------------
module "bucket-signed-file" {
  source = "./modules/bucket-s3-signed-file"
  ## common vars
  infra_env   = var.infra_env
  proj_name   = var.proj_name
  domain_name = var.domain_name
  api_bucket_name_aliases = [
    "app.checkimages",
    "app.accountstatement"
  ]
}

# # ##-------------------------
# # ## S3 Bucket : avatar Vault 
# # ##-------------------------
# # module "bucket-avatar" {
# #   source = "./modules/bucket"
# #   ## common vars
# #   infra_env   = var.infra_env
# #   proj_name   = var.proj_name
# #   domain_name = var.domain_name
# # }

# # ##--------------------------------
# # ## CDN distribution : avatar Vault 
# # ##--------------------------------
# # module "cdn-avatar" {
# #   source = "./modules/cdn"
# #   ## common vars
# #   infra_env   = var.infra_env
# #   proj_name   = var.proj_name
# #   domain_name = var.domain_name
# #   ## modules vars 
# #   avatar_bucket_id                   = module.bucket-avatar.avatar_bucket_id
# #   avatar_bucket_regional_domain_name = module.bucket-avatar.avatar_bucket_regional_domain_name
# #   avatar_bucket_arn                  = module.bucket-avatar.avatar_bucket_arn
# #   public_dns_zone                    = module.public_zone.public_dns_zone // used to create Alias "A" record for ClientApp
# #   avatar_bucket_domain_name          = "images"                           // domain alias
# # }
