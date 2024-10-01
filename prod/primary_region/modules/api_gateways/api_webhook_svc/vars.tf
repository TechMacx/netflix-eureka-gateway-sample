## common varsDNS
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## use in template files
variable "nlb_uri" {} //NLB hostname to add into the template file of webhook [json] file.
variable "vpc_link_id" {}

## Add record to DNS public zone server & custom domain name
variable "acm_arn" {}         // used in Route53 record create for api_custom_domain_name (SSL cert manager) HTTPS listner 
variable "public_dns_zone" {} // Create Route53 "A" record (alias) of webhook API (api_custom_domain_name)


## Webhook Service
variable "webhook_api_gw_cdn" {} //used in line no - 11, 48, 125 (apigateway custom domain name)

## Failover record set & expose external API record URL:
variable "webhook_failover_dns_record" {}
variable "aws_region" {}          // webhookcheck name for DNS
variable "dns_healthcheck_url" {} // used healthcheck_svc api as DNS healthcheck for all apigateway DNS endpoint