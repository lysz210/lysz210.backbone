resource "github_repository" "lysz210_host" {
  name        = "${var.github_repo}"
  description = "Host Application for lysz210.me"
  auto_init = true
}

resource "github_branch" "develop" {
  repository = github_repository.lysz210_host.name
  branch     = "develop"
}
resource "github_branch_default" "default_branch" {
  repository = github_repository.lysz210_host.name
  branch     = github_branch.develop.branch
}
resource "github_actions_variable" "iam_role_arn" {
  repository    = github_repository.lysz210_host.name
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.github_actions_role.arn
}

resource "github_actions_variable" "s3_bucket" {
  repository    = github_repository.lysz210_host.name
  variable_name = "S3_BUCKET_NAME"
  value         = aws_s3_bucket.lysz210_host_storage.id
}

# Crea la variabile per l'ID di CloudFront
resource "github_actions_variable" "cloudfront_id" {
  repository    = github_repository.lysz210_host.name
  variable_name = "CLOUDFRONT_DISTRIBUTION_ID"
  value         = aws_cloudfront_distribution.lysz210_host_distribution.id
}