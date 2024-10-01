##############################################################################################################
// Generate the SSH keypair that we’ll use to configure the EC2 instance.
// After that, write the private key to a local file and upload the public key to AWS
// https://stackoverflow.com/questions/67389324/create-a-key-pair-and-download-the-pem-file-with-terraform-aws
// https://stackoverflow.com/questions/49743220/how-do-i-create-an-ssh-key-in-terraform
// https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
###############################################################################################################
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.infra_env}-${var.proj_name}-keypair-prs"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  filename        = "${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.key.private_key_pem
  file_permission = "0400"
}

######## DEPICATED RESOURCE ##################
# resource "local_file" "private_key" {     
# filename = "${aws_key_pair.key_pair.key_name}.pem"
# sensitive_content = tls_private_key.key.private_key_pem  # local_sensitive_file
# file_permission   = "0400"
# }