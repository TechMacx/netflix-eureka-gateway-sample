resource "aws_s3_bucket" "avatar-bucket" {
  bucket = "${var.infra_env}-${var.proj_name}-avatarvault"
  // acl    = "public-read"
  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-bucket"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

## Block Public Access settings for this bucket
resource "aws_s3_bucket_public_access_block" "avatar-bucket" {
  bucket = aws_s3_bucket.avatar-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ## Bucket policy configure
# resource "aws_s3_bucket_policy" "avatar-bucket" {
#   bucket = aws_s3_bucket.avatar-bucket.id
#   policy = templatefile("${path.module}/templates/src/policy.json", {
#     bucket_name = "${var.infra_env}-${var.proj_name}-avatarvault"
#   })
# }

## CORS policy configure
resource "aws_s3_bucket_cors_configuration" "avatar-bucket" {
  bucket = aws_s3_bucket.avatar-bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE", "HEAD", "GET"]
    allowed_origins = ["http://*", "http://localhost"]
    expose_headers  = ["x-amz-server-side-encryption", "x-amz-request-id", "ETag", "x-amz-id-2", "Access-Control-Allow-Origin", "XMLHttpRequest"]
    max_age_seconds = 3000
  }
}

