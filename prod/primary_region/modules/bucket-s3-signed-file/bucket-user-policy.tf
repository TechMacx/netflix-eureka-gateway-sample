#######################
## IAM Inline Policies
#######################
resource "aws_iam_policy" "api-bucket-access" {
  name        = "${var.infra_env}-${var.proj_name}-api-bucket-access"
  description = "Policy that Allows access to S3 bucket"
  policy = templatefile("${path.module}/templates/src/s3-bucket-policy.json", {
    current_env = var.infra_env,
    proj_name   = var.proj_name
  })
}

####################
## Create IAM users
####################
resource "aws_iam_user" "api-bucket-access" {
  name = "${var.infra_env}-${var.proj_name}-api-bucket-access"
}

resource "aws_iam_access_key" "api-bucket-access" {
  user = aws_iam_user.api-bucket-access.name
}

################################
## Appatched policy to IAM users
################################
resource "aws_iam_policy_attachment" "api-bucket-access" {
  name       = "${var.infra_env}-${var.proj_name}-attachment"
  users      = [aws_iam_user.api-bucket-access.name]
  policy_arn = aws_iam_policy.api-bucket-access.arn
}




