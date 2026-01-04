resource "github_repository" "lysz210_cv" {
  name        = var.github_repo
  description = "Curriculum Vitae Application"
  auto_init   = true
}

resource "github_branch" "develop" {
  repository = github_repository.lysz210_cv.name
  branch     = "develop"
  depends_on = [github_repository.lysz210_cv]
}
resource "github_branch_default" "default_branch" {
  repository = github_repository.lysz210_cv.name
  branch     = github_branch.develop.branch
}

data "aws_region" "current" {}

resource "github_actions_variable" "s3_bucket_region" {
  repository    = github_repository.lysz210_cv.name
  variable_name = "AWS_REGION"
  value         = data.aws_region.current.id
}
resource "github_actions_variable" "iam_role_arn" {
  repository    = github_repository.lysz210_cv.name
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.github_actions_role.arn
}

resource "github_actions_variable" "s3_bucket" {
  repository    = github_repository.lysz210_cv.name
  variable_name = "S3_BUCKET_NAME"
  value         = aws_s3_bucket.lysz210_cv_storage.id
}

resource "github_actions_variable" "lambda_function_name" {
  repository    = github_repository.lysz210_cv.name
  variable_name = "LAMBDA_FUNCTION_NAME"
  value         = aws_lambda_function.nuxt_server.function_name
}

# Crea la variabile per l'ID di CloudFront
resource "github_actions_variable" "cloudfront_id" {
  repository    = github_repository.lysz210_cv.name
  variable_name = "CLOUDFRONT_DISTRIBUTION_ID"
  value         = aws_cloudfront_distribution.lysz210_cv_distribution.id
}