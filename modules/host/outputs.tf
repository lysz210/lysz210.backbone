output "repo_url" {
  value = github_repository.lysz210_host.html_url
}

output "repo_ssh" {
  value = github_repository.lysz210_host.ssh_clone_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.host_storage.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

output "website_url" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.aliases[0]}"
}