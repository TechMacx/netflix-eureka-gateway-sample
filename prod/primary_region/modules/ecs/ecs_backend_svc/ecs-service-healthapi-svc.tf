#####################################################
## ecs_tasks_security_group.tf  
#####################################################
# Traffic to the ECS cluster should only come from the NLB
resource "aws_security_group" "healthapi" {
  name        = "${var.infra_env}-${var.proj_name}-HealthApi-EcsContainer-SecurityGroup"
  description = "Allow Inbound Access From VPC to HealthApi Containers"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.healthapi_app_port
    to_port     = var.healthapi_app_port
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "VPC-CIDR to Farget-Conteaners" // CKV_AWS_23 ; https://docs.bridgecrew.io/docs/networking_31
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Farget-Conteaners to ALL" // CKV_AWS_23 ; https://docs.bridgecrew.io/docs/networking_31
  }

  tags = {
    Name = "${var.infra_env}-${var.proj_name}-HealthApi-EcsContainer"
  }
}

#####################################################
## ecs.tf  
#####################################################
data "template_file" "healthapi" {
  template = file("${path.module}/templates/ecs/ecs_healthapi.json.tpl")

  vars = {
    infra_env                = var.infra_env
    proj_name                = var.proj_name
    healthapi_svc_image      = var.healthapi_svc_image
    healthapi_app_port       = var.healthapi_app_port
    healthapi_fargate_cpu    = var.healthapi_fargate_cpu
    healthapi_fargate_memory = var.healthapi_fargate_memory
    aws_region               = var.aws_region
    //aws_account_id           = data.aws_elb_service_account.main.arn
  }
}

resource "aws_ecs_task_definition" "healthapi" {
  family                   = "${var.infra_env}-${var.proj_name}-HealthApi"
  execution_role_arn       = aws_iam_role.healthapi_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.healthapi_ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.healthapi_fargate_cpu
  memory                   = var.healthapi_fargate_memory
  container_definitions    = data.template_file.healthapi.rendered
}

resource "aws_ecs_service" "healthapi" {
  name            = "${var.infra_env}-${var.proj_name}-HealthApi"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.healthapi.arn
  desired_count   = var.healthapi_desired_count //"${var.app_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.healthapi.id]
    subnets          = var.aws_subnet_private
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.healthapi.id
    //container_name should be same as name of template file's "name" tag
    //https://stackoverflow.com/questions/62104862/the-container-does-not-exist-in-the-task-definition
    container_name = "${var.infra_env}-${var.proj_name}-HealthApi"
    container_port = var.healthapi_app_port
  }
  depends_on = [aws_lb_listener.healthapi_backend_tcp, aws_iam_role_policy_attachment.healthapi_ecs_task_execution_role, aws_iam_role_policy_attachment.healthapi_ecs_task_role]
}

#####################################################
## ecs_roles.tf  
#####################################################
# ECS "task role" data
# https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/
data "aws_iam_policy_document" "healthapi_ecs_task_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS "task role"
resource "aws_iam_role" "healthapi_ecs_task_role" {
  name               = "${var.infra_env}-${var.proj_name}-healthapi-task-role-${var.cluster_name}" //TaskRole
  assume_role_policy = data.aws_iam_policy_document.healthapi_ecs_task_role.json
}

# ECS "task role" policy attachment
resource "aws_iam_role_policy_attachment" "healthapi_ecs_task_role" {
  role       = aws_iam_role.healthapi_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

## ---------------------------
# ECS task execution role data
data "aws_iam_policy_document" "healthapi_ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

## Task execution: inline policy creation for secretmanager & parameeters group. 
resource "aws_iam_policy" "healthapi_ecs_task_execution_inline_policy" {
  name        = "${var.infra_env}-${var.proj_name}-HealthSvc-SecretManagerAccess-${var.cluster_name}"
  description = "Policy that allows access to Secret Manager keys"
  policy = templatefile("${path.module}/templates/ecs/ecs_task_ssm_policy.json", {
    aws_region     = var.aws_region,
    aws_account_id = var.aws_account_id //data.aws_caller_identity.current.account_id
  })
}

## ECS task execution role
resource "aws_iam_role" "healthapi_ecs_task_execution_role" {
  name               = "${var.infra_env}-${var.proj_name}-healthapi-task-execution-role-${var.cluster_name}" //TaskExecutionRole
  assume_role_policy = data.aws_iam_policy_document.healthapi_ecs_task_execution_role.json
}

## ECS task execution role: AWS managed policy attachment
resource "aws_iam_role_policy_attachment" "healthapi_ecs_task_execution_role" {
  role       = aws_iam_role.healthapi_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

## ECS task execution role: Inline policy attachment for secretmanager & parameeters group
resource "aws_iam_role_policy_attachment" "healthapi_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.healthapi_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.healthapi_ecs_task_execution_inline_policy.arn
}

#####################################################
## auto_scaling.tf
#####################################################
resource "aws_appautoscaling_target" "healthapi_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.healthapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.healthapi_scale_min_capacity
  max_capacity       = var.healthapi_scale_max_capacity
}

# Automatically scale ECS task capacity UP by one
resource "aws_appautoscaling_policy" "healthapi_up" {
  name               = "healthapi_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.healthapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.healthapi_target]
}

# Automatically scale ECS task capacity DOWN by one
resource "aws_appautoscaling_policy" "healthapi_down" {
  name               = "healthapi_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.healthapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.healthapi_target]
}

# CloudWatch CPU alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "healthapi_service_cpu_high" {
  alarm_name          = "healthapi_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.healthapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.healthapi_up.arn]
}

# CloudWatch CPU alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "healthapi_service_cpu_low" {
  alarm_name          = "healthapi_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.healthapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.healthapi_down.arn]
}

##--------------------
## auto_scaling memory
##--------------------
# Automatically scale ECS task capacity UP by one
resource "aws_appautoscaling_policy" "healthapi_mem_up" {
  name               = "healthapi_mem_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.healthapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.healthapi_target]
}

# Automatically scale ECS task capacity DOWN by one
resource "aws_appautoscaling_policy" "healthapi_mem_down" {
  name               = "healthapi_mem_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.healthapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.healthapi_target]
}

# CloudWatch MEMORY alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "healthapi_service_mem_high" {
  alarm_name          = "healthapi_memory_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "95"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.healthapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.healthapi_mem_up.arn]
}

# CloudWatch MEMORY alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "healthapi_service_mem_low" {
  alarm_name          = "healthapi_memory_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.healthapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.healthapi_mem_down.arn]
}

#####################################################
## ecs_logs.tf
#####################################################
# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "healthapi_log_group" {
  name              = "/ecs/healthapi"
  retention_in_days = 30

  tags = {
    Name = "healthapi-log-group"
  }
}

resource "aws_cloudwatch_log_stream" "healthapi_log_stream" {
  name           = "healthapi-log-stream"
  log_group_name = aws_cloudwatch_log_group.healthapi_log_group.name
}
