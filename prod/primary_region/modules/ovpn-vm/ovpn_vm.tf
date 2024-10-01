###############################
## Launch Open VPN EC2 instance
## https://www.middlewareinventory.com/blog/terraform-aws-example-ec2/
###############################
resource "aws_instance" "ovpn" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = flatten(var.ovpn_subnet_ids)[0]
  // associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                = var.keypair_name
  ebs_optimized           = true // CKV_AWS_135: https://docs.bridgecrew.io/docs/ensure-that-ec2-is-ebs-optimized
  monitoring              = true // CKV_AWS_126: https://docs.bridgecrew.io/docs/ensure-that-detailed-monitoring-is-enabled-for-ec2-instances
  disable_api_termination = true

  vpc_security_group_ids = [
    aws_security_group.ovpn-sgp.id
  ]

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name        = "${var.infra_env}-${var.proj_name}-ovpn-ebs"
      Project     = "${var.proj_name}"
      Domain_name = "${var.domain_name}"
      Role        = "EBS - Storage"
      Environment = var.infra_env
      ManagedBy   = "terraform"
    }
  }

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-ovpn"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "EC2 - compute"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [aws_security_group.ovpn-sgp]
}

## Optional either use aws_eip OR aws_eip_association 
#####################################################
## Associate EIP with EC2 Instance - Using the instance attribute of aws_eip
resource "aws_eip" "ovpn-eip" {
  vpc      = true
  instance = aws_instance.ovpn.id

  tags = {
    Name        = "${var.infra_env}-${var.proj_name}-ovpn-eip"
    Project     = "${var.proj_name}"
    Domain_name = "${var.domain_name}"
    Role        = "EC2 - compute"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }

  depends_on = [var.current_vpc_igw]
}

# ## Associate EIP with EC2 Instance - using aws_eip_association resource
# resource "aws_eip_association" "demo-eip-association" {
#   instance_id   = aws_instance.demo-instance.id
#   allocation_id = aws_eip.demo-eip.id
# }