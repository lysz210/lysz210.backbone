# 1. Creazione della Hosted Zone principale
resource "aws_route53_zone" "main" {
  name          = "lysz210.name"
  comment       = "Managed by Terraform - Core Infrastructure"
  force_destroy = false
}

# 2. Record TXT per Keybase (Verifica Sito)
resource "aws_route53_record" "keybase_verification" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lysz210.name"
  type    = "TXT"
  ttl     = 172800
  records = ["keybase-site-verification=CSIcI9LwdT2ZCbeyPqVAEIL0Z65TSaByfWoVkeku5Gc"]
}
# 3. Record per GitHub Pages (Sottodominio Photos)
resource "aws_route53_record" "github_photos_cname" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "photos.gh.lysz210.name"
  type    = "CNAME"
  ttl     = 172800
  records = ["lysz210.github.io"]
}

# Record TXT per la sfida di GitHub Pages (Challenge)
resource "aws_route53_record" "github_pages_challenge" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_github-pages-challenge-lysz210.photos.gh.lysz210.name"
  type    = "TXT"
  ttl     = 172800
  records = ["7374b0f9786fbb7925623491b200e4"]
}

# 4. Certificato Wildcard (Gestito centralmente)
resource "aws_acm_certificate" "wildcard" {
  provider                  = aws.us_east_1 # Deve essere in us-east-1 per CloudFront
  domain_name               = "*.lysz210.name"
  subject_alternative_names = ["lysz210.name"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wildcard-lysz210-name"
  }
}

# Record DNS per la validazione automatica del certificato
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# 5. Export dei parametri su SSM (Per i futuri Microfrontend)
resource "aws_ssm_parameter" "zone_id" {
  name  = "/infra/core/route53_zone_id"
  type  = "String"
  value = aws_route53_zone.main.zone_id
}

resource "aws_ssm_parameter" "wildcard_cert_arn" {
  name  = "/infra/core/wildcard_cert_arn"
  type  = "String"
  value = aws_acm_certificate.wildcard.arn
}

# Output utili da vedere a terminale
output "name_servers" {
  description = "Nuovi Name Servers da inserire nel pannello Registered Domains"
  value       = aws_route53_zone.main.name_servers
}