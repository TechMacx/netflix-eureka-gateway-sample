output "dns_healthcheck_url" {
  value = aws_route53_health_check.health.id
}