########################################
## Creat api gateway [Regional REST Api]
########################################
# Create API Gateway
resource "aws_api_gateway_rest_api" "health" {
  body = templatefile("${path.module}/templates/src/healthcheck.json", {
    api_title         = "${var.infra_env}-${var.proj_name}-healthcheck-api",
    nlb_uri           = var.nlb_uri,
    vpc_link_id       = var.vpc_link_id,
    api_custom_domain = "${var.health_api_gw_cdn}.${var.domain_name}",
    env               = "${var.infra_env}"
    }
  )
  put_rest_api_mode = "overwrite" // ["overwrite" or "merge"] default is overwrite
  name              = "${var.infra_env}-${var.proj_name}-healthcheck-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Deploy json body to the api gateway
resource "aws_api_gateway_deployment" "health" {
  rest_api_id = aws_api_gateway_rest_api.health.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.health.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Add api-gateway client certificate
resource "aws_api_gateway_client_certificate" "health" {
  description = "healthchek_certificate_cs"
}

## Create a deployment stage (e.g. uat/pro/dev)
resource "aws_api_gateway_stage" "health" {
  deployment_id         = aws_api_gateway_deployment.health.id
  rest_api_id           = aws_api_gateway_rest_api.health.id
  client_certificate_id = aws_api_gateway_client_certificate.health.id
  stage_name            = var.infra_env
}

###########################################
## Create API Gateway [CUSTOM DOMAIN NAME]
###########################################
## create domain name
resource "aws_api_gateway_domain_name" "health" {
  domain_name              = "${var.health_api_gw_cdn}.${var.domain_name}"
  regional_certificate_arn = var.acm_arn
  security_policy          = "TLS_1_2" // CKV_AWS_206; https://docs.bridgecrew.io/docs/ensure-aws-api-gateway-domain-uses-a-modern-security-policy

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

## AWS API gateway STAGE base_PATH mapping with custom domain name
resource "aws_api_gateway_base_path_mapping" "health" {
  api_id      = aws_api_gateway_rest_api.health.id
  stage_name  = aws_api_gateway_stage.health.stage_name
  domain_name = aws_api_gateway_domain_name.health.domain_name
}

###############################################################
## Add api-gateway custom domain name record to Route53 service
###############################################################
# health DNS record using Route53.
resource "aws_route53_record" "health" {
  name    = aws_api_gateway_domain_name.health.domain_name
  type    = "A"
  zone_id = var.public_dns_zone

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.health.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.health.regional_zone_id
  }
}

## Create "Route53 Health Check" for Failover routing.
resource "aws_route53_health_check" "health" {
  // https://developer.hashicorp.com/terraform/language/functions/substr
  // https://developer.hashicorp.com/terraform/language/functions/trim
  //fqdn              = trim("${aws_api_gateway_deployment.health.invoke_url}", "https://")
  fqdn              = aws_route53_record.health.fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "env/test"
  failure_threshold = "5"
  request_interval  = "10"

  tags = {
    Name = "${var.aws_region}-healthcheck-pri-api"
  }
}