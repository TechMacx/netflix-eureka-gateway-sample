############################################
# Create Security Group for the NAT instance
############################################
resource "aws_security_group" "nat-gw" {
  name        = "${var.infra_env}-${var.proj_name}-nat-gatewat"
  description = "${var.infra_env}-${var.proj_name}-nat-gateway"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow Public SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "Allow Public HTTP port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "Allow Public HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "Allow all traffic from VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
    Name        = "${var.infra_env}-${var.proj_name}-nat-gw"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "natgw-security-group"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
  depends_on = [aws_vpc.vpc]
}

#####################################################
## https://stackoverflow.com/questions/60218940/how-do-i-launch-an-ec2-instance-into-an-existing-vpc-using-terraform
## https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/464 (get single subnet ID as string)
#####################################################

resource "aws_network_interface" "nat-nic" {
  subnet_id         = flatten(aws_subnet.public.*.id)[0] // get single subnet ID as string
  security_groups   = [aws_security_group.nat-gw.id]
  source_dest_check = false // source/destination must disable when NAT gateway used this NIC 
  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-NAT-nic"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "nat_network_interface"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

}

resource "aws_eip" "nat-eip" {
  vpc               = true
  network_interface = aws_network_interface.nat-nic.id
  depends_on        = [aws_internet_gateway.igw, aws_subnet.public]
}

resource "aws_instance" "nat" {
  ami           = var.nat_ami_id
  instance_type = var.instance_type
  key_name      = var.keypair_name

  # ebs_optimized = true // CKV_AWS_135: https://docs.bridgecrew.io/docs/ensure-that-ec2-is-ebs-optimized
  monitoring = false // CKV_AWS_126: https://docs.bridgecrew.io/docs/ensure-that-detailed-monitoring-is-enabled-for-ec2-instances

  # https://stackoverflow.com/questions/63374810/network-interface-conflicts-with-subnet-id-terraform-aws-provider
  # subnet_id  = flatten(var.ovpn_subnet_ids)[0]   //You shouldn't have subnet_id when you use network_interface
  network_interface {
    network_interface_id = aws_network_interface.nat-nic.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-nat"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "EC2 - compute"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}
