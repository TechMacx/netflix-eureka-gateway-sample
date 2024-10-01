output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "current_vpc_igw" {
  value = aws_internet_gateway.igw
}

output "aws_subnet_public" {
  value = aws_subnet.public.*.id
}

output "aws_subnet_private" {
  value = aws_subnet.private.*.id
}

output "aws_subnet_isolated" {
  value = aws_subnet.isolated.*.id
}

output "rds_subnet_group" {
  value = aws_db_subnet_group.subnet_group.name
}