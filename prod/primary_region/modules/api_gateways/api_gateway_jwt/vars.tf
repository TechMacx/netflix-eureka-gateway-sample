## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}
variable "cluster_name" {}

## use in template files
variable "nlb_uri" {} //NLB hostname to add into the template file of clientapp [json] file.
variable "vpc_link_id" {}

## Add record to DNS public zone server & custom domain name
variable "acm_arn" {}         // used in Route53 record create for api_custom_domain_name (SSL cert manager) HTTPS listner 
variable "public_dns_zone" {} // Create Route53 "A" record (alias) of ClientApp API (api_custom_domain_name)

## lambda jwt authorizer lambda variables 
## ClientAapp
variable "clientapp_jwtauth_name" {}
variable "clientapp_jwks_uri" {}
variable "clientapp_token_issuer" {}
variable "clientapp_api_gw_cdn" {} //used in line no - 11, 48, 125 (apigateway custom domain name)
variable "audience" {}

## Failover record set & expose external API record URL:
variable "clientapp_failover_dns_record" {}
variable "aws_region" {}          // healthcheck name for DNS
variable "dns_healthcheck_url" {} // used healthcheck_svc api as DNS healthcheck for all apigateway DNS endpoint

## Lambda Logging and Monitoring
variable "lambda_insights_layers" {}