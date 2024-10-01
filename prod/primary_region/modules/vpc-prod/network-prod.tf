## network.tf
## ----------

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-vpc"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                                       = var.az_count
  cidr_block                                  = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_cidr_block, count.index)
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc.id
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-public"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "public-subnet"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count                                       = var.az_count
  cidr_block                                  = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_cidr_block, var.az_count + count.index)
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc.id
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-private"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "private-subnet"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Create var.az_count isolated subnets, each in a different AZ
resource "aws_subnet" "isolated" {
  count                                       = var.az_count
  cidr_block                                  = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnet_cidr_block, var.az_count + 1 + (count.index + 1))
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc.id
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-isolated"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "isolated-subnet"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-igw"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "internet-gateway"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

## Create a public routetable & add routes
resource "aws_route_table" "public_rtb" {
  # count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-public-rtb"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "Public routetable"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Route the public subnets traffic through the IGW
resource "aws_route_table_association" "public_rtb_association" {
  count     = var.az_count
  subnet_id = element(aws_subnet.public.*.id, count.index)
  # route_table_id = element(aws_route_table.public_rtb.*.id, count.index)
  route_table_id = aws_route_table.public_rtb.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "ngw_eip" {
  count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  count             = var.az_count
  subnet_id         = element(aws_subnet.public.*.id, count.index)
  allocation_id     = element(aws_eip.ngw_eip.*.id, count.index)
  connectivity_type = "public"

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-ngw"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "NAT-gateway"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-private-rtb"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "Private routetable"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

## Create a isolated routetable & add routes
resource "aws_route_table" "isolated_rtb" {
  # count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-isolated-rtb"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "isolated routetable"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

# Route the isolated subnets within the VPC CIDR.
resource "aws_route_table_association" "isolated_rtb_association" {
  count     = var.az_count
  subnet_id = element(aws_subnet.isolated.*.id, count.index)
  # route_table_id = element(aws_route_table.public_rtb.*.id, count.index)
  route_table_id = aws_route_table.isolated_rtb.id
}

## Default Security-Group
## "Ensure the default security group of every VPC restricts all traffic"
// CKV2_AWS_12: https://docs.bridgecrew.io/docs/networking_4
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}