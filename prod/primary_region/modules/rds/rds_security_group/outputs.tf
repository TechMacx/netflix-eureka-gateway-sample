// used in rds modules
output "database_secruty_group" {
  value = aws_security_group.rds_sg.id
}