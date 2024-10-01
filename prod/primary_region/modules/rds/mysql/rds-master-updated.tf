#############################
# RDS MySQL Database Resource
#############################
resource "aws_db_instance" "rds" {

  identifier = "${var.infra_env}-${var.proj_name}-restapi-master" #var.db_identifier_name
  engine     = var.db_engine
  port       = var.db_port
  username   = "admin"
  password   = random_password.adm_password.result
  //db_name    = "${var.proj_name}_db"

  engine_version        = var.db_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_alloc_storage
  max_allocated_storage = var.db_max_alloc_storage

  vpc_security_group_ids     = [var.rds_secruty_group] // aws_security_group.rds_sg.id
  db_subnet_group_name       = var.rds_subnet_group
  parameter_group_name       = var.db_param_group
  skip_final_snapshot        = true
  multi_az                   = true # false if do not use production (cost involved) // CKV_AWS_157: https://docs.bridgecrew.io/docs/general_73
  storage_encrypted          = true
  copy_tags_to_snapshot      = true
  backup_retention_period    = 30
  auto_minor_version_upgrade = true // CKV_AWS_226:  https://docs.bridgecrew.io/docs/ensure-aws-db-instance-gets-all-minor-upgrades-automatically
  deletion_protection        = true // CKV_AWS_293: 
  //  monitoring_interval        = 5 // CKV_AWS_118: https://docs.bridgecrew.io/docs/ensure-that-enhanced-monitoring-is-enabled-for-amazon-rds-instances
  enabled_cloudwatch_logs_exports = ["audit", "general", "error", "slowquery"]

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-mysql-master"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "RDS Database"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
  depends_on = [random_password.adm_password]
}