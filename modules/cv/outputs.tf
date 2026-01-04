output "repo_url" {
  value = github_repository.lysz210_cv.html_url
}

output "repo_ssh" {
  value = github_repository.lysz210_cv.ssh_clone_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.lysz210_cv_storage.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.lysz210_cv_distribution.id
}

output "lambda_function_name" {
  value = aws_lambda_function.lysz210_cv_function.function_name
}

output "website_url" {
  value = "https://${aws_route53_record.lysz210_cv_alias.name}"
}