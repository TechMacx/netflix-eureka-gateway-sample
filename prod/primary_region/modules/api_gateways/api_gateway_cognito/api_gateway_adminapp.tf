#########################################
### Creat api gateway [Regional REST Api]
#########################################
# Create API Gateway
resource "aws_api_gateway_rest_api" "adminapp" {
  body = templatefile("${path.module}/templates/src/consoleapi-swagger-cognito.json", {
    api_title         = "${var.infra_env}-${var.proj_name}-console-api",
    nlb_uri           = var.nlb_uri,
    vpc_link_id       = var.vpc_link_id,
    api_custom_domain = "${var.adminapp_api_gw_cdn}.${var.domain_name}",
    env               = "${var.infra_env}",
    cognito_arn       = aws_cognito_user_pool.adminapp-pool.arn
    # cognito_arn       = data.aws_cognito_user_pools.adminapp-pool.arns  // used when existing cognito pool being used
    }
  )
  put_rest_api_mode = "overwrite"                                     // ["overwrite" or "merge"] default is overwrite
  name              = "${var.infra_env}-${var.proj_name}-console-api" // name always overwrite api_title
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  lifecycle {
    create_before_destroy = true
  }
  // depends_on = [aws_lambda_function.adminapp_jwt_authorizer] // if authorization enabled and used jwt lambda authorizer for auth0 
}

## Deploy json body to the api gateway
resource "aws_api_gateway_deployment" "adminapp" {
  rest_api_id = aws_api_gateway_rest_api.adminapp.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.adminapp.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Add api-gateway client certificate
resource "aws_api_gateway_client_certificate" "adminapp" {
  description = "adminapp_certificate_cs"
}

## Create a deployment stage (e.g. uat/pro/dev)
resource "aws_api_gateway_stage" "adminapp" {
  deployment_id         = aws_api_gateway_deployment.adminapp.id
  rest_api_id           = aws_api_gateway_rest_api.adminapp.id
  client_certificate_id = aws_api_gateway_client_certificate.adminapp.id // CKV2_AWS_51: 
  stage_name            = var.infra_env

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.adminapp_cloudwatch.arn
    format          = "$context.requestId"
  }
  depends_on = [aws_cloudwatch_log_group.adminapp_cloudwatch]
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
resource "aws_api_gateway_method_settings" "adminapp_cloudwatch" {
  rest_api_id = aws_api_gateway_rest_api.adminapp.id
  stage_name  = aws_api_gateway_stage.adminapp.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    //data_trace_enabled     = true  // full access to logs [Full request and response logs]
    logging_level          = "ERROR"
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
  depends_on = [aws_api_gateway_stage.adminapp]
}

resource "aws_cloudwatch_log_group" "adminapp_cloudwatch" {
  name              = "/aws/apigateway/console-api"
  retention_in_days = 30

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-console-api-loggroup"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "API Gateway Cloudwatch LogGroup"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}


###################################
## API Gateway [CUSTOM DOMAIN NAME]
###################################
## create domain name
resource "aws_api_gateway_domain_name" "adminapp" {
  domain_name              = "${var.adminapp_api_gw_cdn}.${var.domain_name}"
  regional_certificate_arn = var.acm_arn
  security_policy          = "TLS_1_2" // CKV_AWS_206; https://docs.bridgecrew.io/docs/ensure-aws-api-gateway-domain-uses-a-modern-security-policy
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

## AWS API gateway STAGE base_PATH mapping with custom domain name
resource "aws_api_gateway_base_path_mapping" "adminapp" {
  api_id      = aws_api_gateway_rest_api.adminapp.id
  stage_name  = aws_api_gateway_stage.adminapp.stage_name
  domain_name = aws_api_gateway_domain_name.adminapp.domain_name
}

###############################################################
## Add api-gateway custom domain name record to Route53 service
###############################################################
# adminapp DNS record using Route53.
resource "aws_route53_record" "adminapp" {
  name    = aws_api_gateway_domain_name.adminapp.domain_name
  type    = "A"
  zone_id = var.public_dns_zone
  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.adminapp.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.adminapp.regional_zone_id
  }
}
