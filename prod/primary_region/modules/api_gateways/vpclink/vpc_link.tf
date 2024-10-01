resource "aws_api_gateway_vpc_link" "internal-nlb" {
  name        = "${var.infra_env}-${var.proj_name}-endpoint"
  description = ""
  target_arns = [var.backend_nlb_arn]

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-endpoint"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "vpc-links"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}
