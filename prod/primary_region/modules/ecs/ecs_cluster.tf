resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.infra_env}-${var.proj_name}-ecs-cluster"

  setting { // CKV_AWS_65: https://docs.bridgecrew.io/docs/bc_aws_logging_11
    name  = "containerInsights"
    value = "enabled"
  }
}
