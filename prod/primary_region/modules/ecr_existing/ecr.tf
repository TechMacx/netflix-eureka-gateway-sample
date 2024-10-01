data "aws_ecr_repository" "adminapp" {
  name = var.frontend-adminapp
}

data "aws_ecr_repository" "walletapp" {
  name = var.frontend-walletapp
}

data "aws_ecr_repository" "restapi_svc" {
  name = var.backend-restapi-svc
}

data "aws_ecr_repository" "health_svc" {
  name = var.backend-health-svc
}

data "aws_ecr_repository" "webhook_svc" {
  name = var.backend-webhook-svc
}