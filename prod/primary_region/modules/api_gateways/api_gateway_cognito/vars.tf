## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}
variable "cluster_name" {}

## adminapp [json] template files variables
variable "nlb_uri" {} //NLB hostname to add into the template file of adminapp [json] file.
variable "vpc_link_id" {}

## Add record to DNS public zone server & custom domain name
variable "acm_arn" {}         // used in Route53 record create for api_custom_domain_name (SSL cert manager) HTTPS listner 
variable "public_dns_zone" {} // Create Route53 "A" record (alias) of adminApp API (api_custom_domain_name)

## ClientAapp
variable "adminapp_api_gw_cdn" {} //used in line no - 15, 52, 142 << prefix custom domain name [e.g - "${adminapp_api_gw_cdn}.${var.domain_name}"]

## lambda post login
variable "ses_email_addresses" {} // used in Post Login scripts for Cognito EMAIL verification; lambda_post_login.tf;

## Failover record set & expose external API record URL:
variable "aws_region" {}                   //declear in dns healthcheck
variable "adminapp_failover_dns_record" {} //used for failover CNAME record
variable "dns_healthcheck_url" {}          // used healthcheck_svc api as DNS healthcheck for all apigateway DNS endpoint