## Add "Route53 records" for Failover routing exposed URLs for AdminApp (used when Failover DNS routing is required)
resource "aws_route53_health_check" "webhook_failover" {
  fqdn = aws_lb.backend.dns_name
  port = 80
  type = "TCP"
  //resource_path     = "env/health"
  failure_threshold = "5"
  request_interval  = "10"

  tags = {
    Name = "${var.aws_region}-webhook-pri-ui-hc"
  }
}

resource "aws_route53_record" "webhook_failover" {
  zone_id = var.public_dns_zone
  name    = "webhook-api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 10

  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.webhook_failover.id
  set_identifier  = "webhook-pri-ui-hc"
  records         = [aws_lb.backend.dns_name]
}