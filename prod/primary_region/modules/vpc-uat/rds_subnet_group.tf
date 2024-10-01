#########################################
####  RDS Resources (RDS Subnet Group) 
#########################################
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.infra_env}-${var.proj_name}-db-subnet-grp"
  subnet_ids = aws_subnet.isolated.*.id //var.rds_subnet_group

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-db-subnet-grp"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "RDS Subnet group"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}



