# L'ID della Zona DNS per creare i record dei sottodomini (es. cv.lysz210.me)
output "route53_zone_id" {
  description = "ID della zona Route53 per i record DNS dei Microfrontend"
  value       = aws_route53_zone.main.zone_id
}

# L'ARN del certificato SSL Wildcard (*.lysz210.me)
output "acm_certificate_arn" {
  description = "ARN del certificato SSL da usare nelle distribuzioni CloudFront dei MF"
  value       = aws_acm_certificate.wildcard.arn
}

output "lysz210_host_repo_url" {
  description = "URL della repository GitHub"
  value       = module.lysz210_host.repo_url
}

output "lysz210_host_repo_ssh" {
  description = "URL SSH della repository GitHub"
  value       = module.lysz210_host.repo_ssh
}

output "lysz210_host_s3_bucket" {
  description = "Nome del bucket S3 per l'hosting"
  value       = module.lysz210_host.s3_bucket_name
}

output "lysz210_host_cloudfront_id" {
  description = "ID della distribuzione CloudFront"
  value       = module.lysz210_host.cloudfront_id
}

output "lysz210_host_website_url" {
  description = "URL pubblico del sito"
  value       = module.lysz210_host.website_url
}