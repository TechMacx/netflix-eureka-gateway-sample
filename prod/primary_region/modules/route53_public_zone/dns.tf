## Public Hosted Zone
resource "aws_route53_zone" "public" {
  name = var.domain_name

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-public_zone"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "public-zone"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}