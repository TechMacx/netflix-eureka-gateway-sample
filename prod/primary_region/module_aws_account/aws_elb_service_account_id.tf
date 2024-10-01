data "aws_elb_service_account" "main" {}

output "elb_account_id" { // ELB account ID fetch by using Terraform
  value = data.aws_elb_service_account.main.arn
}