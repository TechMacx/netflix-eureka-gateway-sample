# outputs.tf 
## used in json template for api gateways
output "backend_nlb_hostname" {
  value = aws_lb.backend.dns_name
}

## used in API-gateway modules /vpc_links/
output "backend_nlb_arn" {
  value = aws_lb.backend.arn
}