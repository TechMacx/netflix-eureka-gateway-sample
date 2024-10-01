output "public_dns_zone" {
  value = aws_route53_zone.public.id
}