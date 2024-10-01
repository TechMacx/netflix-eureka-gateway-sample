## common varsDNS
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## use in template files
variable "nlb_uri" {} //NLB hostname to add into the template file of health [json] file.
variable "vpc_link_id" {}

## Add record to DNS public zone server & custom domain name
variable "acm_arn" {}         // used in Route53 record create for api_custom_domain_name (SSL cert manager) HTTPS listner 
variable "public_dns_zone" {} // Create Route53 "A" record (alias) of health API (api_custom_domain_name)

## lambda jwt authorizer lambda variables 
## ClientAapp
variable "health_api_gw_cdn" {} //used in line no - 11, 48, 125 (apigateway custom domain name)

## Failover record set & expose external API record URL:
//variable "health_failover_dns_record" {}
variable "aws_region" {} // healthcheck name for DNS