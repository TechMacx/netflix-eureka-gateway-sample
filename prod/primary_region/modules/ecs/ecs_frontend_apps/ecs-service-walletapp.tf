#####################################################
## ecs_tasks_security_group.tf  
#####################################################

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "walletapp" {
  name        = "${var.infra_env}-${var.proj_name}-WalletApp-EcsContainer-SecurityGroup"
  description = "Allow Inbound Access From ALB/VPC to WalletApp Containers"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.walletapp_frontend_app_port
    to_port         = var.walletapp_frontend_app_port
    security_groups = [aws_security_group.alb.id]
    description     = "Frontend ALB to Farget-Conteaners"
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.walletapp_frontend_app_port
    to_port     = var.walletapp_frontend_app_port
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "VPC-CIDR to Farget-Conteaners"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.infra_env}-${var.proj_name}-WalletApp-EcsContainer"
  }
}


#####################################################
## ecs.tf  
#####################################################
# resource "aws_ecs_cluster" "main" {
#   name = "cb-cluster"
# }

data "template_file" "walletapp" {
  template = file("${path.module}/templates/ecs/ecs_walletapp.json.tpl") // https://www.chakray.com/creating-fargate-ecs-task-aws-using-terraform/

  vars = {
    infra_env                   = var.infra_env
    proj_name                   = var.proj_name
    aws_region                  = var.aws_region
    walletapp_image             = var.walletapp_image
    walletapp_frontend_app_port = var.walletapp_frontend_app_port
    walletapp_fargate_cpu       = var.walletapp_fargate_cpu
    walletapp_fargate_memory    = var.walletapp_fargate_memory

  }
}

resource "aws_ecs_task_definition" "walletapp" {
  family                   = "${var.infra_env}-${var.proj_name}-WalletApp"
  execution_role_arn       = aws_iam_role.walletapp_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.walletapp_ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.walletapp_fargate_cpu
  memory                   = var.walletapp_fargate_memory
  container_definitions    = data.template_file.walletapp.rendered
}

resource "aws_ecs_service" "walletapp" {
  name            = "${var.infra_env}-${var.proj_name}-WalletApp"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.walletapp.arn
  desired_count   = var.walletapp_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.walletapp.id]
    subnets          = var.aws_subnet_private
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.walletapp.id
    //{container_name of lb should be same as name of template file's "name"}
    //https://stackoverflow.com/questions/62104862/the-container-does-not-exist-in-the-task-definition
    container_name = "${var.infra_env}-${var.proj_name}-WalletApp"
    container_port = var.walletapp_frontend_app_port
  }

  depends_on = [aws_alb_listener.frontend_http, aws_iam_role_policy_attachment.walletapp_ecs_task_execution_role, aws_iam_role_policy_attachment.walletapp_ecs_task_role]
}

#####################################################
## ecs_roles.tf
#####################################################
# ECS "task role" data
# https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/
data "aws_iam_policy_document" "walletapp_ecs_task_role" {
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
resource "aws_iam_role" "walletapp_ecs_task_role" {
  name               = "${var.infra_env}-${var.proj_name}-walletapp-task-role-${cluster_name}" //TaskRole
  assume_role_policy = data.aws_iam_policy_document.walletapp_ecs_task_role.json
}

# ECS "task role" policy attachment
resource "aws_iam_role_policy_attachment" "walletapp_ecs_task_role" {
  role       = aws_iam_role.walletapp_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

## ----------------------------------------------------------------------------------------------##
# ECS task execution role data
data "aws_iam_policy_document" "walletapp_ecs_task_execution_role" {
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

# ECS task execution role
resource "aws_iam_role" "walletapp_ecs_task_execution_role" {
  name               = "${var.infra_env}-${var.proj_name}-walletapp-task-execution-role-${cluster_name}" //TaskExecutionRole
  assume_role_policy = data.aws_iam_policy_document.walletapp_ecs_task_execution_role.json
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "walletapp_ecs_task_execution_role" {
  role       = aws_iam_role.walletapp_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#####################################################
## auto_scaling.tf
#####################################################

resource "aws_appautoscaling_target" "walletapp_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.walletapp.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.walletapp_scale_min_capacity
  max_capacity       = var.walletapp_scale_max_capacity
}

# Automatically scale capacity UP by one
resource "aws_appautoscaling_policy" "walletapp_up" {
  name               = "walletapp_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.walletapp.name}"
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

  depends_on = [aws_appautoscaling_target.walletapp_target]
}

# Automatically scale capacity DOWN by one
resource "aws_appautoscaling_policy" "walletapp_down" {
  name               = "walletapp_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.walletapp.name}"
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

  depends_on = [aws_appautoscaling_target.walletapp_target]
}

# CloudWatch alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "walletapp_service_cpu_high" {
  alarm_name          = "walletapp_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.walletapp.name
  }

  alarm_actions = [aws_appautoscaling_policy.walletapp_up.arn]
}

# CloudWatch alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "walletapp_service_cpu_low" {
  alarm_name          = "walletapp_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.walletapp.name
  }

  alarm_actions = [aws_appautoscaling_policy.walletapp_down.arn]
}

##--------------------
## auto_scaling memory
##--------------------
# Automatically scale capacity UP by one
resource "aws_appautoscaling_policy" "walletapp_mem_up" {
  name               = "walletapp_mem_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.walletapp.name}"
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
  depends_on = [aws_appautoscaling_target.walletapp_target]
}

# Automatically scale capacity DOWN by one
resource "aws_appautoscaling_policy" "walletapp_mem_down" {
  name               = "walletapp_mem_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.walletapp.name}"
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
  depends_on = [aws_appautoscaling_target.walletapp_target]
}

# CloudWatch alarm that triggers the autoscaling UP policy
resource "aws_cloudwatch_metric_alarm" "walletapp_service_mem_high" {
  alarm_name          = "walletapp_memory_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "95"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.walletapp.name
  }
  alarm_actions = [aws_appautoscaling_policy.walletapp_mem_up.arn]
}

# CloudWatch alarm that triggers the autoscaling DOWN policy
resource "aws_cloudwatch_metric_alarm" "walletapp_service_mem_low" {
  alarm_name          = "walletapp_memory_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.walletapp.name
  }
  alarm_actions = [aws_appautoscaling_policy.walletapp_mem_down.arn]
}

#####################################################
## ecs_logs.tf
#####################################################

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "walletapp_log_group" {
  name              = "/ecs/walletapp"
  retention_in_days = 30

  tags = {
    Name = "walletapp-log-group"
  }
}

resource "aws_cloudwatch_log_stream" "walletapp_log_stream" {
  name           = "walletapp-log-stream"
  log_group_name = aws_cloudwatch_log_group.walletapp_log_group.name
}
