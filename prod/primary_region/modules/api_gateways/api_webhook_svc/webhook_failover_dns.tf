###########################################################################################
## Add HealthCheck DNS record & add CNAME failover routing policy record to Route53 service
###########################################################################################

## Create API Gateway "CUSTOM DOMAINNAME" for Failover exposed URLs
resource "aws_api_gateway_domain_name" "webhook_failover" {
  domain_name              = "${var.webhook_failover_dns_record}.${var.domain_name}"
  regional_certificate_arn = var.acm_arn
  security_policy          = "TLS_1_2" // CKV_AWS_206; https://docs.bridgecrew.io/docs/ensure-aws-api-gateway-domain-uses-a-modern-security-policy

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

## AWS API gateway STAGE base_PATH mapping with custom domain name
resource "aws_api_gateway_base_path_mapping" "webhook_failover" {
  api_id      = aws_api_gateway_rest_api.webhook.id
  stage_name  = aws_api_gateway_stage.webhook.stage_name
  domain_name = aws_api_gateway_domain_name.webhook_failover.domain_name
}

# ## Create "Route53 Health Check" for Failover routing.
# resource "aws_route53_health_check" "webhook" {
#   // https://developer.hashicorp.com/terraform/language/functions/substr
#   // https://developer.hashicorp.com/terraform/language/functions/trim
#   //fqdn              = trim("${aws_api_gateway_deployment.webhook.invoke_url}", "https://")
#   fqdn              = aws_route53_record.webhook.fqdn
#   port              = 443
#   type              = "HTTPS"
#   resource_path     = "env/test"
#   failure_threshold = "5"
#   request_interval  = "10"

#   tags = {
#     Name = "${var.aws_region}-webhook-pri-api-hc"
#   }
# }

## Add "Route53 records" for Failover routing exposed URLs.
resource "aws_route53_record" "webhook_failover" {

  zone_id = var.public_dns_zone
  name    = var.webhook_failover_dns_record
  type    = "CNAME"
  ttl     = 10

  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = var.dns_healthcheck_url // aws_route53_health_check.webhook.id
  set_identifier  = "webhook-pri-api-hc"
  records         = [aws_route53_record.webhook.fqdn]
}
