resource "aws_flow_log" "flowlogs" {
  iam_role_arn    = aws_iam_role.flowlogs.arn
  log_destination = aws_cloudwatch_log_group.flowlogs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  name              = "${var.infra_env}-${var.proj_name}-vpc-flowlogs"
  retention_in_days = 60
}

data "aws_iam_policy_document" "flowlogs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlogs" {
  name               = "flowlogs"
  assume_role_policy = data.aws_iam_policy_document.flowlogs_assume_role.json
}

data "aws_iam_policy_document" "flowlogs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlogs" {
  name   = "flowlogs"
  role   = aws_iam_role.flowlogs.id
  policy = data.aws_iam_policy_document.flowlogs.json
}