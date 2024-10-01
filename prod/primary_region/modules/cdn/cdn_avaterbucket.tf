##########################
### Create CF Distrubution
##########################
resource "aws_cloudfront_distribution" "s3_avatar_distribution" {
  aliases = ["images.${var.domain_name}"] // depends on custom SSL certs
  comment = "application-avatar-images"
  origin {
    domain_name = var.avatar_bucket_regional_domain_name
    origin_id   = var.avatar_bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_avatar_identity.cloudfront_access_identity_path
    }
  }
  enabled = true

  default_cache_behavior {
    compress               = true
    target_origin_id       = var.avatar_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.s3_avatar_cache_policy.id
  }

  # viewer_certificate {
  #   cloudfront_default_certificate = true
  # }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.global_certs.arn //"${var.acm_certificate_arn}"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      # restriction_type = "whitelist"
      # locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-cf"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "CF Distribution s3 origin"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

}

################################
### OAI (Origin Access Identity)
################################
## origin_access_identity 
resource "aws_cloudfront_origin_access_identity" "s3_avatar_identity" {
  comment = "access-identity-${var.avatar_bucket_regional_domain_name}"
}

## bucket policy document
data "aws_iam_policy_document" "avatar_s3_policy_document" {
  statement {
    sid       = "CDNPublicReadGetObject"
    actions   = ["s3:GetObject"]
    resources = ["${var.avatar_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_avatar_identity.iam_arn]
    }
  }
}

## add bucket policy
resource "aws_s3_bucket_policy" "avatar_s3_policy" {
  bucket = var.avatar_bucket_id
  policy = data.aws_iam_policy_document.avatar_s3_policy_document.json
}


##############################
### [CF - Custom Cache Policy]
##############################
resource "aws_cloudfront_cache_policy" "s3_avatar_cache_policy" {
  name        = "${var.infra_env}-${var.proj_name}-cache-policy"
  comment     = "Inherited from Default policy when CF compression is enabled"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

########################################
### [CF - ACM Global domain certificate]
### REGION - N. Virginia (us-east-1)
### Used for CDN /s3 bucket/ etc
########################################

provider "aws" {
  alias                    = "nv_global"
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "nuestro-uat"
}

## Generate wildcard certificate in ACM 
resource "aws_acm_certificate" "global_certs" {
  provider                  = aws.nv_global
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = ["${var.domain_name}"]

  validation_method = "DNS"

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-global-cert"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "SSL-Global"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#####################
### Route 53 Records
#####################
# cf distribution DNS record using Route53.
resource "aws_route53_record" "cdn_alias" {
  zone_id = var.public_dns_zone
  name    = "${var.avatar_bucket_domain_name}.${var.domain_name}"
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.s3_avatar_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_avatar_distribution.hosted_zone_id

  }
}

