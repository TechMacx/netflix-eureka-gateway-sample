## nlb.tf  
#########
resource "aws_lb" "backend" {
  name                             = "${var.infra_env}-${var.proj_name}-internal-nlb"
  subnets                          = var.aws_subnet_private
  internal                         = true
  load_balancer_type               = "network"
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true // CKV_AWS_152 ; https://docs.bridgecrew.io/docs/ensure-that-load-balancer-networkgateway-has-cross-zone-load-balancing-enabled

  // NLB access logs : access_logs & bucket-nlb-accesslogs.tf
  access_logs {
    bucket  = aws_s3_bucket.network-lb-logs.bucket
    prefix  = var.nlb_accesslog_prefix //check the module - "ecs_backend_svc" under main.tf 
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-internal-nlb"
    Project     = "${var.proj_name}"
    Role        = "Network Load Balancer"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
  depends_on = [aws_s3_bucket_policy.network-lb-logs] // NLB access logs : access_logs & bucket-nlb-accesslogs.tf
}

# # [TCP (80) rule] forward traffic from the NLB to the target group.
# resource "aws_lb_listener" "restapi_backend_tcp" {
#   load_balancer_arn = aws_lb.backend.id
#   port              = var.http_tcp_port
#   protocol          = "TCP"

#   default_action {
#     target_group_arn = aws_lb_target_group.restapi.id
#     type             = "forward"
#   }
# }

# # [TLS (443) rule] forward traffic from the NLB to the target group.
# resource "aws_lb_listener" "restapi_backend_tls" {
#   load_balancer_arn = aws_lb.backend.id
#   port              = var.https_tls_port
#   protocol          = "TLS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.acm_arn

#   default_action {
#     target_group_arn = aws_lb_target_group.restapi.id
#     type             = "forward"
#   }
# }

## ----------------------------
## restapi-svc-ecs-service.tf 
## ----------------------------
resource "aws_lb_listener" "restapi_backend_tcp" {
  load_balancer_arn = aws_lb.backend.id
  port              = var.restapi_app_port // port - 8080
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.restapi.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "restapi" {
  name        = "${var.infra_env}-${var.proj_name}-RestApi"
  port        = var.restapi_app_port // port - 8080
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}

## ----------------------------
## healthapi-svc-ecs-service.tf 
## ----------------------------
resource "aws_lb_listener" "healthapi_backend_tcp" {
  load_balancer_arn = aws_lb.backend.id
  port              = var.healthapi_app_port // port - 8181
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.healthapi.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "healthapi" {
  name        = "${var.infra_env}-${var.proj_name}-HealthApi"
  port        = var.healthapi_app_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}

## ----------------------------
## Webhook-svc-ecs-service.tf 
## ----------------------------
resource "aws_lb_listener" "webhook_backend_tcp" {
  load_balancer_arn = aws_lb.backend.id
  port              = var.webhook_app_port // port - 8000
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.webhook.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "webhook" {
  name        = "${var.infra_env}-${var.proj_name}-Webhook"
  port        = var.webhook_app_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}