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

output "website" {
  description = "Dettagli dell'applicazione principale"
  value       = {
    host = module.lysz210_host
    cv   = module.lysz210_cv
  }
}