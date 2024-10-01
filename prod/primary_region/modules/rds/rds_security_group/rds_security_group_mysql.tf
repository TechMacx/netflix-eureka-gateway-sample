#########################################
####  RDS Resources (RDS Security Group) 
#########################################
resource "aws_security_group" "rds_sg" {
  name        = "${var.infra_env}-${var.proj_name}-rds-sg"
  description = "Allow DB from VPC subnet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL/PostgreSQL from VPC"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    description      = "MySQL Outbound Connection"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-rds-sg"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "rds-master-security-group"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}