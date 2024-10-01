## Private hosted zone
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-private_zone"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "private_zone"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

}