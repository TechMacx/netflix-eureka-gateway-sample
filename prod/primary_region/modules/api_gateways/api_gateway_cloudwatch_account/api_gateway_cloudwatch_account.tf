# ### https://medium.com/rockedscience/api-gateway-logging-with-terraform-d13f7701ed0b
# ### https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account

## API gateways cloudwatch Account
resource "aws_api_gateway_account" "api_cloudwatch" {
  cloudwatch_role_arn = aws_iam_role.api_cloudwatch.arn
}

## IAM role for API gateways Cloudwatch Account
resource "aws_iam_role" "api_cloudwatch" {
  name = "${var.infra_env}-${var.proj_name}-apigateway-cloudwatch-global-role-${var.cluster_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

## IAM role ploicy for API gateways Cloudwatch Account
resource "aws_iam_role_policy" "api_cloudwatch" {
  name = "default"
  role = aws_iam_role.api_cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

###############################################
### Creat Api gateway Account [alternative way]
###############################################


# resource "aws_api_gateway_account" "api_cloudwatch" {
#   cloudwatch_role_arn = aws_iam_role.api_cloudwatch.arn
# }

# data "aws_iam_policy_document" "api_cloudwatch_trust_relationships" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }
#     actions = ["sts:AssumeRole"]
#   }
#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

# resource "aws_iam_role" "api_cloudwatch" {
#   name               = "${var.infra_env}-${var.proj_name}-payment-api-cloudwatch-role"
#   assume_role_policy = data.aws_iam_policy_document.api_cloudwatch_trust_relationships.json
# }

# data "aws_iam_policy_document" "api_cloudwatch" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:DescribeLogGroups",
#       "logs:DescribeLogStreams",
#       "logs:PutLogEvents",
#       "logs:GetLogEvents",
#       "logs:FilterLogEvents",
#     ]

#     resources = ["*"]
#   }

#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

# resource "aws_iam_role_policy" "api_cloudwatch" {
#   name   = "${var.infra_env}-${var.proj_name}-payment-api-cloudwatch-role-policy"
#   role   = aws_iam_role.api_cloudwatch.id
#   policy = data.aws_iam_policy_document.api_cloudwatch.json
# }