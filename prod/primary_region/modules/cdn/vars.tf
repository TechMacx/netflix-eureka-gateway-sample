## common vars
variable "infra_env" {}
variable "proj_name" {}
variable "domain_name" {}

## S3 Bucket ID (avatar vault bucket id)
variable "avatar_bucket_id" {}
variable "avatar_bucket_regional_domain_name" {}
variable "avatar_bucket_arn" {}
variable "public_dns_zone" {}           // Create Route53 "A" record (alias) of adminApp API (api_custom_domain_name)
variable "avatar_bucket_domain_name" {} //Route53 A redord endpoint
