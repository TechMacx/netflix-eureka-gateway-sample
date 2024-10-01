## nlb.tf  
#########

resource "aws_lb" "backend" {
  name                             = "${var.infra_env}-${var.proj_name}-webhook-nlb"
  subnets                          = var.aws_subnet_private
  internal                         = false
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true // CKV_AWS_152 ; https://docs.bridgecrew.io/docs/ensure-that-load-balancer-networkgateway-has-cross-zone-load-balancing-enabled

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-webhook-nlb"
    Project     = "${var.proj_name}"
    Role        = "Network Load Balancer"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# # [TCP (80) rule] forward traffic from the NLB to the target group.
# resource "aws_lb_listener" "webhook_backend_tcp" {
#   load_balancer_arn = aws_lb.backend.id
#   port              = var.http_tcp_port
#   protocol          = "TCP"

#   default_action {
#     target_group_arn = aws_lb_target_group.webhook.id
#     type             = "forward"
#   }
# }

# [TLS (443) rule] forward traffic from the NLB to the target group.
resource "aws_lb_listener" "webhook_backend_tls" {
  load_balancer_arn = aws_lb.backend.id
  port              = var.https_tls_port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" //"ELBSecurityPolicy-2016-08" [ CKV_AWS_103: https://docs.bridgecrew.io/docs/bc_aws_general_43 ]
  certificate_arn   = var.acm_arn

  default_action {
    target_group_arn = aws_lb_target_group.webhook.id
    type             = "forward"
  }
}

## webhook-svc-ecs-service.tf
resource "aws_lb_target_group" "webhook" {
  name        = "${var.infra_env}-${var.proj_name}-webhook"
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