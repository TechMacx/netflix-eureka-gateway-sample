## Public Hosted Zone - fetching existing zone
data "aws_route53_zone" "public" {
  zone_id      = var.zone_id
  private_zone = false

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-public_zone"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "public-zone"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}