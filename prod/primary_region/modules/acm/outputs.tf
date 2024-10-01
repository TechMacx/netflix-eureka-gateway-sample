output "acm_arn" {
  value = aws_acm_certificate.certs.id // Used in ECS service ALB & NLB HTTPS/TLS listners
}
