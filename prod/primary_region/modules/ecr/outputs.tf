# output "adminapp_image" {
#   value = data.aws_ecr_repository.adminapp.repository_url
# }

output "adminapp_image" {
  value = aws_ecr_repository.adminapp.repository_url
}

output "walletapp_image" {
  value = aws_ecr_repository.walletapp.repository_url
}

output "restapi_svc_image" {
  value = aws_ecr_repository.restapi_svc.repository_url
}

output "healthapi_svc_image" {
  value = aws_ecr_repository.health_svc.repository_url
}

output "webhook_svc_image" {
  value = aws_ecr_repository.webhook_svc.repository_url
}