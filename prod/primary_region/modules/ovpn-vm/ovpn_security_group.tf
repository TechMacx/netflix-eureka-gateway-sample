#################################################
# Create Security Group for the Open VPN instance
#################################################
resource "aws_security_group" "ovpn-sgp" {
  name        = "${var.infra_env}-${var.proj_name}-ovpn-sg"
  description = "${var.infra_env}-${var.proj_name}-ovpn-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH access" // CKV_AWS_23 ; https://docs.bridgecrew.io/docs/networking_31
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "Allow HTTPS access" // CKV_AWS_23 ; https://docs.bridgecrew.io/docs/networking_31
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]

  }

  ingress {
    description = "Allow custom OVPN port"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]

  }

  ingress {
    description = "Allow custom OVPN port"
    from_port   = 945
    to_port     = 945
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]

  }

  ingress {
    description = "Allow custom OVPN port"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name        = "${var.infra_env}-${var.proj_name}-openvpn-sg"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "ovpn-security-group"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}