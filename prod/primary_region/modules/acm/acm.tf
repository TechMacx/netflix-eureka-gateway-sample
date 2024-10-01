## Generate wildcard certificate in ACM 
resource "aws_acm_certificate" "certs" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = ["${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-cert"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "SSL"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Validate ACM certificate by usine Domain validation
data "aws_route53_zone" "acm_domain" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "certs" {
  for_each = {
    for dvo in aws_acm_certificate.certs.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.acm_domain.zone_id
}

resource "aws_acm_certificate_validation" "certs" {
  certificate_arn         = aws_acm_certificate.certs.arn
  validation_record_fqdns = [for record in aws_route53_record.certs : record.fqdn]
}