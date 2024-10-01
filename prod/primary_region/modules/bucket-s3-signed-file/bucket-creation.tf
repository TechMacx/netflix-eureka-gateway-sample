/*--------------------------------------------------
 * S3 Buckets
 * The resource block will create all the buckets in the variable array
 *-------------------------------------------------*/
resource "random_id" "api_bucket" {
  count       = length(var.api_bucket_name_aliases)
  byte_length = 12
}

resource "aws_s3_bucket" "api_bucket" {
  count  = length(var.api_bucket_name_aliases)
  bucket = "${var.infra_env}-${var.proj_name}-${var.api_bucket_name_aliases[count.index]}-${random_id.api_bucket[count.index].hex}"
}
## Block Public Access settings for this bucket
resource "aws_s3_bucket_public_access_block" "api_bucket" {
  count                   = length(var.api_bucket_name_aliases)
  bucket                  = element(aws_s3_bucket.api_bucket.*.id, count.index)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
