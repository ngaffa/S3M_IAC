resource "aws_s3_bucket" "s3m-bucket-angular" {
  bucket = "s3m-bucket-angular"
  acl    = "public-read"
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
  policy = file("policies/s3-policy.json")
  tags = {
    Name        = "s3m-bucket-angular"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "s3m-bucket-angular-ab" {
  bucket              = aws_s3_bucket.s3m-bucket-angular.id
  block_public_acls   = true
  block_public_policy = true
}