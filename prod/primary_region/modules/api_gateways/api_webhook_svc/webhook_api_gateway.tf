###########################################################
## Add api-gateway - Resource Policy : Whitelist IP address
###########################################################
## https://beabetterdev.com/2021/09/29/api-gateway-allow-ip-tutorial/
data "aws_iam_policy_document" "webhook" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["*"]
  }
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["*"]
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = ["44.231.31.224/32", "44.235.206.45/32", "52.13.208.146/32"]
    }
  }
}

# ## Deploy Resource Policy 
# resource "aws_api_gateway_rest_api_policy" "webhook" {
#   rest_api_id = aws_api_gateway_rest_api.webhook.id
#   policy      = data.aws_iam_policy_document.webhook.json
#   depends_on = [aws_api_gateway_rest_api.webhook]
# }

########################################
## Creat api gateway [Regional REST Api]
########################################
# Create API Gateway
resource "aws_api_gateway_rest_api" "webhook" {
  body = templatefile("${path.module}/templates/src/webhook.json", {
    api_title         = "${var.infra_env}-${var.proj_name}-webhook-api",
    nlb_uri           = var.nlb_uri,
    vpc_link_id       = var.vpc_link_id,
    api_custom_domain = "${var.webhook_api_gw_cdn}.${var.domain_name}",
    env               = "${var.infra_env}"
    }
  )
  put_rest_api_mode = "overwrite" // ["overwrite" or "merge"] default is overwrite
  name              = "${var.infra_env}-${var.proj_name}-webhook-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }

  policy     = data.aws_iam_policy_document.webhook.json // Resource Policy : Whitelist IP address
  depends_on = [data.aws_iam_policy_document.webhook]    // Resource Policy : Whitelist IP address
}

## Deploy json body to the api gateway
resource "aws_api_gateway_deployment" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.webhook.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Add api-gateway client certificate
resource "aws_api_gateway_client_certificate" "webhook" {
  description = "webhook_certificate_cs"
}

## delay stage deployment for Resource Policy : Whitelist IP address
resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
}

## Create a deployment stage (e.g. uat/pro/dev)
resource "aws_api_gateway_stage" "webhook" {
  deployment_id         = aws_api_gateway_deployment.webhook.id
  rest_api_id           = aws_api_gateway_rest_api.webhook.id
  client_certificate_id = aws_api_gateway_client_certificate.webhook.id
  stage_name            = var.infra_env
  depends_on            = [time_sleep.wait_30_seconds] // Resource Policy : Whitelist IP address
}


#########################################################
### Create a CloudWatch LOG group for API gateways metrix
#########################################################
## https://stackoverflow.com/questions/52156285/terraform-how-to-enable-api-gateway-execution-logging
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings
## https://medium.com/rockedscience/api-gateway-logging-with-terraform-d13f7701ed0b
## https://github.com/hashicorp/terraform-provider-aws/issues/7306
## https://github.com/cloudposse/terraform-aws-api-gateway

# Create a API gateway cloudwatch logs for stage (e.g. uat/pro/dev)
resource "aws_api_gateway_method_settings" "webhook_cloudwatch" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id
  stage_name  = aws_api_gateway_stage.webhook.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    //data_trace_enabled     = true  // full access to logs [Full request and response logs]
    logging_level          = "ERROR"
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
  depends_on = [aws_api_gateway_stage.webhook]
}

resource "aws_cloudwatch_log_group" "webhook_cloudwatch" {
  name              = "/aws/apigateway/webhook-api"
  retention_in_days = 60

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-webhook-api-loggroup"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "API Gateway Cloudwatch LogGroup"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

###########################################
## Create API Gateway [CUSTOM DOMAIN NAME]
###########################################
## create domain name
resource "aws_api_gateway_domain_name" "webhook" {
  domain_name              = "${var.webhook_api_gw_cdn}.${var.domain_name}"
  regional_certificate_arn = var.acm_arn
  security_policy          = "TLS_1_2" // CKV_AWS_206; https://docs.bridgecrew.io/docs/ensure-aws-api-gateway-domain-uses-a-modern-security-policy

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

## AWS API gateway STAGE base_PATH mapping with custom domain name
resource "aws_api_gateway_base_path_mapping" "webhook" {
  api_id      = aws_api_gateway_rest_api.webhook.id
  stage_name  = aws_api_gateway_stage.webhook.stage_name
  domain_name = aws_api_gateway_domain_name.webhook.domain_name
}

###############################################################
## Add api-gateway custom domain name record to Route53 service
###############################################################
# webhook DNS record using Route53.
resource "aws_route53_record" "webhook" {
  name    = aws_api_gateway_domain_name.webhook.domain_name
  type    = "A"
  zone_id = var.public_dns_zone

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.webhook.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.webhook.regional_zone_id
  }
}
