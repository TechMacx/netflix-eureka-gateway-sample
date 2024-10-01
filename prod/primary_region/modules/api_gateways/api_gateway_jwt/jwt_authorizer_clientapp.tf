###################################################
## CREATE - AUTH 0 jwt_authorizer (LAMBDA function)
###################################################
# ## Create IAM policy document for jwt_authorizer
# data "aws_iam_policy_document" "jwt_authorizer" {
#   version = "2012-10-17"
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
#     }
#   }
# }

## create IAM role for jwt_authorizer
resource "aws_iam_role" "jwt_authorizer" {
  name = "${var.infra_env}-${var.proj_name}-clientapp-jwt-auth-role-${var.cluster_name}"
 ` ## assume_role_policy = data.aws_iam_policy_document.jwt_authorizer.json  // enable only, If you use above "data.aws_iam_policy_document" 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
      },
      "Action": ["sts:AssumeRole"]
    }
  ]
}
EOF
}

## Attached AWSLambdaRole IAM policy for Lambda basic execution role 
resource "aws_iam_role_policy_attachment" "jwt_authorizer" {
  role       = aws_iam_role.jwt_authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

## Attached AWSLambdaBasicExecutionRole IAM policy for Lambda basic execution role 
resource "aws_iam_role_policy_attachment" "jwt_authorizer_execution" {
  role       = aws_iam_role.jwt_authorizer.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

## Enhance Loging and Monitoring
## https://stackoverflow.com/questions/65735878/how-to-configure-cloudwatch-lambda-insights-in-terraform
## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versionsx86-64.html
## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started-cli.html
## Attached CloudWatchLambdaInsightsExecutionRolePolicy IAM policy for Lambda enhance monitoring 
resource "aws_iam_role_policy_attachment" "jwt_authorizer_insights_policy" {
  role       = aws_iam_role.jwt_authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

## Create LAMBDA function for jwt_authorizer
resource "aws_lambda_function" "jwt_authorizer" {
  function_name    = var.clientapp_jwtauth_name
  filename         = "${path.module}/templates/src/custom-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/templates/src/custom-authorizer.zip")
  role             = aws_iam_role.jwt_authorizer.arn
  handler          = "index.handler" //"authorize.handler"
  runtime          = "nodejs16.x"
  description      = "${var.infra_env}-${var.proj_name}-clientapp-jwt-authorizer" //lambda configuration parameters
  memory_size      = 128
  timeout          = 30
  // reserved_concurrent_executions = 150 // CKV_AWS_115 ; https://docs.bridgecrew.io/docs/ensure-that-aws-lambda-function-is-configured-for-function-level-concurrent-execution-limit
  # tracing_config {  // CKV_AWS_50 ; https://docs.bridgecrew.io/docs/bc_aws_serverless_4
  #   mode = "Active"
  # }
  ephemeral_storage {
    size = 512
  }
  environment {
    variables = {
      JWKS_URI     = var.clientapp_jwks_uri
      TOKEN_ISSUER = var.clientapp_token_issuer
      AUDIENCE     = "https://${var.audience}.${var.domain_name}/" // name should be same as per api_custom_domain_name
    }
  }

  ## Lambda Logging and Monitoring
  ## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versionsx86-64.html
  ## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started-cli.html
  layers = [
    "${var.lambda_insights_layers}"
  ]
}