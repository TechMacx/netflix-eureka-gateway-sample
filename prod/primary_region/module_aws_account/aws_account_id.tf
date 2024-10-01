data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id //get aws account ID 
}

output "aws_caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "aws_caller_user" {
  value = data.aws_caller_identity.current.user_id
}
