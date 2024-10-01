#####################################################
## security_group.tf  
#####################################################
# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "alb" {
  name        = "${var.infra_env}-${var.proj_name}-ALB-securitygroup"
  description = "Allow Public Internet Access To ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.alb_http_port
    to_port     = var.alb_http_port
    cidr_blocks = ["0.0.0.0/0"]
    description = "Internet to Frontend ALB"
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.alb_https_port
    to_port     = var.alb_https_port
    cidr_blocks = ["0.0.0.0/0"]
    description = "Internet to Frontend ALB"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.infra_env}-${var.proj_name}-ALB-securitygroup"
  }
}

#####################################################
## alb.tf  
#####################################################
resource "aws_alb" "frontend" {
  name                             = "${var.infra_env}-${var.proj_name}-external-alb"
  subnets                          = var.aws_subnet_public
  security_groups                  = [aws_security_group.alb.id]
  enable_deletion_protection       = true
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb-logs.bucket
    prefix  = var.alb_accesslog_prefix //check the module - "ecs_frontend_apps" under main.tf 
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-external-alb"
    Project     = "${var.proj_name}"
    Role        = "Application Load Balancer"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
  depends_on = [aws_s3_bucket_policy.alb-logs] // wait for bucket policy to be deployed 
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "frontend_http" {
  load_balancer_arn = aws_alb.frontend.id
  port              = var.alb_http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  // if traffic forwarded to target group
  # default_action {
  #   target_group_arn = aws_alb_target_group.walletapp.id
  #   type             = "forward"
  # }
}

# [HTTPS default rule] redirect all HTTPS traffic from the ALB to the target group.
resource "aws_alb_listener" "frontend_https" {
  load_balancer_arn = aws_alb.frontend.id
  port              = var.alb_https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" //"ELBSecurityPolicy-2016-08" [ CKV_AWS_103: https://docs.bridgecrew.io/docs/bc_aws_general_43 ]
  certificate_arn   = var.acm_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "404"
    }
  }
}
## -----------------------------------------------------------------------------------
## walletapp-ecs-service.tf
## -----------------------------------------------------------------------------------
resource "aws_alb_target_group" "walletapp" {
  name        = "${var.infra_env}-${var.proj_name}-WalletApp"
  port        = var.walletapp_frontend_app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

# [HTTPS host base rule] forward traffic from the ALB to the target group.
resource "aws_lb_listener_rule" "host_based_routing" {
  listener_arn = aws_alb_listener.frontend_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.walletapp.id
  }

  condition {
    host_header {
      values = ["wallet.${var.domain_name}"]
    }
  }
}

# ## EITHER:
# ## --------
# # Create DNS A record for WalletApp.
# resource "aws_route53_record" "walletapp_aias" {
#   zone_id = var.public_dns_zone
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = "dualstack.${aws_alb.frontend.dns_name}"
#     zone_id                = aws_alb.frontend.zone_id
#     evaluate_target_health = true
#   }
# }

## OR:
## ---
## Add "Route53 records" for Failover routing exposed URLs for WalletApp (used when Failover DNS routing is required)
resource "aws_route53_health_check" "walletapp_frontend" {
  fqdn = aws_alb.frontend.dns_name
  port = 80
  type = "HTTP"
  //resource_path     = "env/health"
  failure_threshold = "5"
  request_interval  = "10"

  tags = {
    Name = "${var.aws_region}-wallet-pri-ui-hc"
  }
}

resource "aws_route53_record" "walletapp_frontend_failover" {
  zone_id = var.public_dns_zone
  name    = "wallet.${var.domain_name}"
  type    = "CNAME"
  ttl     = 10

  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.walletapp_frontend.id
  set_identifier  = "wallet-pri-ui-hc"
  records         = [aws_alb.frontend.dns_name]
}

## -----------------------------------------------------------------------------------
## adminapp-ecs-service.tf
## -----------------------------------------------------------------------------------
resource "aws_alb_target_group" "adminapp" {
  name        = "${var.infra_env}-${var.proj_name}-AdminApp"
  port        = var.adminapp_frontend_app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

# [HTTPS host base rule] forward traffic from the ALB to the target group.
resource "aws_lb_listener_rule" "adminapp_host_based_routing" {
  listener_arn = aws_alb_listener.frontend_https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.adminapp.id
  }

  condition {
    host_header {
      values = ["adminapp.${var.domain_name}"]
    }
  }
}

## EITHER:
## --------
## Create DNS A record for AdminApp. (used when Failover DNS routing not required)
# resource "aws_route53_record" "adminapp_aias" {
#   zone_id = var.public_dns_zone
#   name    = "adminapp.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = "dualstack.${aws_alb.frontend.dns_name}"
#     zone_id                = aws_alb.frontend.zone_id
#     evaluate_target_health = true
#   }
# }

## OR:
## ---
## Add "Route53 records" for Failover routing exposed URLs for AdminApp (used when Failover DNS routing is required)
resource "aws_route53_health_check" "adminapp_frontend" {
  fqdn = aws_alb.frontend.dns_name
  port = 80
  type = "HTTP"
  //resource_path     = "env/health"
  failure_threshold = "5"
  request_interval  = "10"

  tags = {
    Name = "${var.aws_region}-adminapp-pri-ui-hc"
  }
}

resource "aws_route53_record" "adminapp_frontend_failover" {
  zone_id = var.public_dns_zone
  name    = "adminapp.${var.domain_name}"
  type    = "CNAME"
  ttl     = 10

  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.adminapp_frontend.id
  set_identifier  = "adminapp-pri-ui-hc"
  records         = [aws_alb.frontend.dns_name]
}