data "github_repository" "lysz210_host" {
  full_name = "${var.github_owner}/${var.github_repo}"
}

resource "github_actions_variable" "iam_role_arn" {
  repository    = data.github_repository.lysz210_host.full_name
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.github_actions_role.arn
}

resource "github_actions_variable" "s3_bucket" {
  repository    = data.github_repository.lysz210_host.full_name
  variable_name = "S3_BUCKET_NAME"
  value         = aws_s3_bucket.lysz210_host_storage.id
}

# Crea la variabile per l'ID di CloudFront
resource "github_actions_variable" "cloudfront_id" {
  repository    = data.github_repository.lysz210_host.full_name
  variable_name = "CLOUDFRONT_DISTRIBUTION_ID"
  value         = aws_cloudfront_distribution.lysz210_host_distribution.id
}