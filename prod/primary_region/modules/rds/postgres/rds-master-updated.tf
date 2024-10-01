################################################################################
# Secret Manager - generate secret for RDS Resource
################################################################################
# Firstly create a random generated password to use in secrets.
resource "random_password" "password" {
  length           = 16
  special          = false
  override_special = "!#()-[]<>_%@"
}

# Creating a AWS secret for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret" "secretmasterDB" {
  name = "${var.infra_env}-${var.proj_name}-master-db"
}

# Creating a AWS secret versions for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.secretmasterDB.id
  secret_string = <<EOF
   {
    "username": "${aws_db_instance.rds.username}",
    "password": "${aws_db_instance.rds.password}",
    "dbname": "restapi",
    "engine": "${aws_db_instance.rds.engine}",
    "port": "${aws_db_instance.rds.port}",
    "dbInstanceIdentifier": "${aws_db_instance.rds.identifier}",
    "dbhost": "${aws_db_instance.rds.address}",
    "dbNameCurrencyCloud": "currencycloudapi_db"
   }
EOF
  depends_on    = [aws_db_instance.rds]
}

################################################################################
# RDS Resource
################################################################################
resource "aws_security_group" "rds_sg" {
  name        = "${var.infra_env}-${var.proj_name}-rds-sg"
  description = "Allow DB from VPC subnet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow PostgreSQL from VPC"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
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

resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.infra_env}-${var.proj_name}-db-subnet-grp"
  subnet_ids = var.rds_subnet_group

  tags = {
    Name = "${var.infra_env}-${var.proj_name}-db-subnet-grp"
  }
}

resource "aws_db_instance" "rds" {

  identifier = "${var.infra_env}-${var.proj_name}-restapi-master" #var.db_identifier_name
  engine     = var.db_engine
  port       = var.db_port
  username   = "pgadmin"
  password   = random_password.password.result
  //db_name    = "postgres" //"${var.proj_name}_db" this is optional

  engine_version        = var.db_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_alloc_storage
  max_allocated_storage = var.db_max_alloc_storage

  vpc_security_group_ids     = [aws_security_group.rds_sg.id]
  db_subnet_group_name       = aws_db_subnet_group.subnet_group.name # var.rds_subnet_group
  parameter_group_name       = var.db_param_group
  skip_final_snapshot        = true
  multi_az                   = true # false if do not use production (cost involved)
  storage_encrypted          = true
  deletion_protection        = true
  auto_minor_version_upgrade = true // CKV_AWS_16: https://docs.bridgecrew.io/docs/general_4

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-postgres-master"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "postgres-master"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

