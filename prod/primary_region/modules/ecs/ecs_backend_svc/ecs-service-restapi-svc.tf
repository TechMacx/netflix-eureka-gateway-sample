#####################################################
## ecs_tasks_security_group.tf  
#####################################################
# Traffic to the ECS cluster should only come from the NLB
resource "aws_security_group" "restapi" {
  name        = "${var.infra_env}-${var.proj_name}-RestApi-EcsContainer-SecurityGroup"
  description = "Allow Inbound Access From VPC to RestApi Containers"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.restapi_app_port
    to_port     = var.restapi_app_port
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
    Name = "${var.infra_env}-${var.proj_name}-RestApi-EcsContainer"
  }
}

#####################################################
## ecs.tf  
#####################################################
data "template_file" "restapi" {
  template = file("${path.module}/templates/ecs/ecs_restapi.json.tpl")

  vars = {
    infra_env              = var.infra_env
    proj_name              = var.proj_name
    restapi_svc_image      = var.restapi_svc_image
    restapi_app_port       = var.restapi_app_port
    restapi_fargate_cpu    = var.restapi_fargate_cpu
    restapi_fargate_memory = var.restapi_fargate_memory
    aws_region             = var.aws_region
    aws_account_id         = var.aws_account_id //data.aws_caller_identity.current.account_id
  }
}

resource "aws_ecs_task_definition" "restapi" {
  family                   = "${var.infra_env}-${var.proj_name}-RestApi"
  execution_role_arn       = aws_iam_role.restapi_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.restapi_ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.restapi_fargate_cpu
  memory                   = var.restapi_fargate_memory
  container_definitions    = data.template_file.restapi.rendered
}

resource "aws_ecs_service" "restapi" {
  name            = "${var.infra_env}-${var.proj_name}-RestApi"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.restapi.arn
  desired_count   = var.restapi_desired_count // No of Container running behind cluster"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.restapi.id]
    subnets          = var.aws_subnet_private
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.restapi.id
    //container_name should be same as name of template file's "name" tag
    //https://stackoverflow.com/questions/62104862/the-container-does-not-exist-in-the-task-definition
    container_name = "${var.infra_env}-${var.proj_name}-RestApi"
    container_port = var.restapi_app_port
  }
  depends_on = [aws_lb_listener.restapi_backend_tcp, aws_iam_role_policy_attachment.restapi_ecs_task_execution_role, aws_iam_role_policy_attachment.restapi_ecs_task_role]
}

#####################################################
## ecs_roles.tf  
#####################################################
# ECS "task role" data
# https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/
data "aws_iam_policy_document" "restapi_ecs_task_role" {
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
resource "aws_iam_role" "restapi_ecs_task_role" {
  name               = "${var.infra_env}-${var.proj_name}-restapi-task-role-${var.cluster_name}" //TaskRole
  assume_role_policy = data.aws_iam_policy_document.restapi_ecs_task_role.json
}

# ECS "task role" policy attachment
resource "aws_iam_role_policy_attachment" "restapi_ecs_task_role" {
  role       = aws_iam_role.restapi_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

## ---------------------------
# ECS task execution role data
data "aws_iam_policy_document" "restapi_ecs_task_execution_role" {
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
resource "aws_iam_policy" "restapi_ecs_task_execution_inline_policy" {
  name        = "${var.infra_env}-${var.proj_name}-RestApi-SecretManagerAccess-${var.cluster_name}"
  description = "Policy that allows access to Secret Manager keys"
  policy = templatefile("${path.module}/templates/ecs/ecs_task_ssm_policy.json", {
    aws_region     = var.aws_region,
    aws_account_id = var.aws_account_id //data.aws_caller_identity.current.account_id
  })
}

## ECS task execution role
resource "aws_iam_role" "restapi_ecs_task_execution_role" {
  name               = "${var.infra_env}-${var.proj_name}-restapi-task-execution-role-${var.cluster_name}" //TaskExecutionRole
  assume_role_policy = data.aws_iam_policy_document.restapi_ecs_task_execution_role.json
}

## ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "restapi_ecs_task_execution_role" {
  role       = aws_iam_role.restapi_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

## ECS task execution role: Inline policy attachment for secretmanager & parameeters group
resource "aws_iam_role_policy_attachment" "restapi_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.restapi_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.restapi_ecs_task_execution_inline_policy.arn
}

#####################################################
## auto_scaling.tf
#####################################################
resource "aws_appautoscaling_target" "restapi_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.restapi.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.restapi_scale_min_capacity
  max_capacity       = var.restapi_scale_max_capacity
}

# Automatically scale capacity UP by one
resource "aws_appautoscaling_policy" "restapi_up" {
  name               = "restapi_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.restapi.name}"
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
  depends_on = [aws_appautoscaling_target.restapi_target]
}

# Automatically scale capacity DOWN by one
resource "aws_appautoscaling_policy" "restapi_down" {
  name               = "restapi_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.restapi.name}"
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
  depends_on = [aws_appautoscaling_target.restapi_target]
}

# CloudWatch alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "restapi_service_cpu_high" {
  alarm_name          = "restapi_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.restapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.restapi_up.arn]
}

# CloudWatch alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "restapi_service_cpu_low" {
  alarm_name          = "restapi_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.restapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.restapi_down.arn]
}

##--------------------
## auto_scaling memory
##--------------------
# Automatically scale capacity UP by one
resource "aws_appautoscaling_policy" "restapi_mem_up" {
  name               = "restapi_mem_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.restapi.name}"
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
  depends_on = [aws_appautoscaling_target.restapi_target]
}

# Automatically scale capacity DOWN by one
resource "aws_appautoscaling_policy" "restapi_mem_down" {
  name               = "restapi_mem_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.restapi.name}"
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
  depends_on = [aws_appautoscaling_target.restapi_target]
}

# CloudWatch alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "restapi_service_mem_high" {
  alarm_name          = "restapi_memory_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "95"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.restapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.restapi_mem_up.arn]
}

# CloudWatch alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "restapi_service_mem_low" {
  alarm_name          = "restapi_memory_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.restapi.name
  }
  alarm_actions = [aws_appautoscaling_policy.restapi_mem_down.arn]
}

#####################################################
## ecs_logs.tf
#####################################################
# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "restapi_log_group" {
  name              = "/ecs/restapi"
  retention_in_days = 60

  tags = {
    Name = "restapi-log-group"
  }
}

resource "aws_cloudwatch_log_stream" "restapi_log_stream" {
  name           = "restapi-log-stream"
  log_group_name = aws_cloudwatch_log_group.restapi_log_group.name
}
