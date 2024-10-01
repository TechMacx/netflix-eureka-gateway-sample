# ## https://stackoverflow.com/questions/43366038/terraform-elb-s3-permissions-issue
# // https://www.mikulskibartosz.name/terraform-s3-lifecycle-rules/

# data "aws_elb_service_account" "main" {} // ELB account ID fetch by using Terraform
# data "aws_caller_identity" "current" {}  // AWS Account ID fetch by using Terraform
# # output "aws_account_id" {
# #   value = data.aws_caller_identity.current.account_id
# # } 


resource "aws_s3_bucket" "network-lb-logs" {
  bucket = "${var.infra_env}-${var.proj_name}-nlb-accesslogs"
  // acl    = "public-read"

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-nlb-accesslogs"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

## Block Public Access settings for this bucket
resource "aws_s3_bucket_public_access_block" "network-lb-logs" {
  bucket = aws_s3_bucket.network-lb-logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle deletion policy
resource "aws_s3_bucket_lifecycle_configuration" "network-lb-logs" {
  bucket = aws_s3_bucket.network-lb-logs.id

  rule {
    id = "30-days-to-deletion"
    expiration {
      days = 30
    }
    filter {
      prefix = var.nlb_accesslog_prefix //check the module - "ecs_backend_svc" under main.tf 
      # and {
      #   prefix                   = var.nlb_accesslog_prefix  //check the module - "ecs_backend_svc" under main.tf 
      #   # object_size_greater_than = 0
      #   # object_size_less_than    = 500
      # }
    }
    status = "Enabled"
  }
}

## Bucket policy configure for NLB
// https://moonape1226.medium.com/access-denied-for-bucket-please-check-s3bucket-permission-error-when-setting-access-log-for-nlb-72db5c8c81d4
// https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html

resource "aws_s3_bucket_policy" "network-lb-logs" {
  bucket = aws_s3_bucket.network-lb-logs.id
  policy = templatefile("${path.module}/templates/ecs/nlb_accesslog_bucket_policy.json", {
    bucket_name    = "${var.infra_env}-${var.proj_name}-nlb-accesslogs",
    aws_account_id = var.aws_account_id       // data.aws_caller_identity.current.account_id,
    prefix         = var.nlb_accesslog_prefix //check the module - "ecs_backend_svc" under main.tf 
  })
}



