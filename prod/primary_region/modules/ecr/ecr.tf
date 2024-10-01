resource "aws_ecr_repository" "adminapp" {
  name                 = "${var.infra_env}-${var.proj_name}-frontend-adminapp"
  image_tag_mutability = "MUTABLE" //immutable

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "walletapp" {
  name                 = "${var.infra_env}-${var.proj_name}-frontend-walletapp"
  image_tag_mutability = "MUTABLE" //immutable

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "restapi_svc" {
  name                 = "${var.infra_env}-${var.proj_name}-restapi-svc"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "health_svc" {
  name                 = "${var.infra_env}-${var.proj_name}-health-svc"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "webhook_svc" {
  name                 = "${var.infra_env}-${var.proj_name}-webhook-svc"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}