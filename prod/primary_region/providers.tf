terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "nuestro-prod"
}
# provider "aws" {
#   region     = var.aws_region
#   access_key = "XXXXXXXXXXXXXXX"
#   secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# }

