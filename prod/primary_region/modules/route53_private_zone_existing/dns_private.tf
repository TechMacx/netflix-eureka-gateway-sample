## Private hosted zone
resource "aws_route53_zone_association" "secondary" {
  zone_id = var.zone_id
  vpc_id  = var.vpc_id
}