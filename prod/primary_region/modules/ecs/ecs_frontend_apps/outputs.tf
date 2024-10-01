# outputs.tf
output "alb_hostname" {
  value = aws_alb.frontend.dns_name
}

# output "alb_id" {
#   value = aws_alb.frontend.id
# }

# output "aws_alb_zone_id" {
#   value = aws_alb.frontend.id
# }


# output "https_listener_arn" {
#   value = aws_alb_listener.frontend_https.arn
# } 

# output "aws_alb_security_group" {
#   value = aws_security_group.alb.id
# }