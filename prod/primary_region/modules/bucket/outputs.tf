# used in CDN distribution
output "avatar_bucket_id" {
  value = aws_s3_bucket.avatar-bucket.id
}

# used in CDN distribution
output "avatar_bucket_regional_domain_name" {
  value = aws_s3_bucket.avatar-bucket.bucket_regional_domain_name

}

# used in CDN distribution
output "avatar_bucket_arn" {
  value = aws_s3_bucket.avatar-bucket.arn
}
