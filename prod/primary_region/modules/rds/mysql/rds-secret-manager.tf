###################################################
# Secret Manager - generate secret for RDS Resource
###################################################
# Firstly create a random generated password: {admin_user} to use in secrets.
resource "random_password" "adm_password" {
  length           = 25
  special          = false
  override_special = "!#()-[]<>_%@"
}

# Firstly create a random generated password: {limited_user} to use in secrets.
resource "random_password" "restapi_password" {
  length           = 25
  special          = false
  override_special = "!#()-[]<>_%@"
}

# Creating a AWS secret for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret" "secretmasterDB" {
  name = "${var.infra_env}-${var.proj_name}-database-cluster"
}

# Creating a AWS secret versions for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.secretmasterDB.id
  secret_string = <<EOF
   {
    "username": "${aws_db_instance.rds.username}",
    "password": "${aws_db_instance.rds.password}",
    "db_user":"restapi",
    "db_pass":"${random_password.restapi_password.result}",
    "dbname": "nuestro_db",
    "engine": "${aws_db_instance.rds.engine}",
    "port": "${aws_db_instance.rds.port}",
    "dbInstanceIdentifier": "${aws_db_instance.rds.identifier}",
    "dbhost": "${aws_db_instance.rds.address}"
   }
EOF
  depends_on    = [aws_db_instance.rds]
}