# 1. Creazione della Hosted Zone principale
resource "aws_route53_zone" "main" {
  name          = "lysz210.me"
  comment       = "Managed by Terraform - Core Infrastructure"
  force_destroy = false
}

# 2. Record TXT per Keybase (Verifica Sito)
resource "aws_route53_record" "keybase_verification" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lysz210.me"
  type    = "TXT"
  ttl     = 172800
  records = ["keybase-site-verification=CSIcI9LwdT2ZCbeyPqVAEIL0Z65TSaByfWoVkeku5Gc"]
}

# 4. Certificato Wildcard (Gestito centralmente)
resource "aws_acm_certificate" "wildcard" {
  provider                  = aws.us_east_1 # Deve essere in us-east-1 per CloudFront
  domain_name               = "*.lysz210.me"
  subject_alternative_names = ["lysz210.me"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wildcard-lysz210-me"
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

# 1. Chiave KMS per la firma DNSSEC ($1.00/mese)
resource "aws_kms_key" "dnssec" {
  provider                 = aws.us_east_1
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  description              = "KMS Key for DNSSEC - lysz210.me"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*" # In produzione qui metteresti l'ARN del tuo utente IAM
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. Key Signing Key (KSK)
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "lysz210-ksk"
}

# 3. Abilitazione della firma sulla zona
resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on     = [aws_route53_key_signing_key.main]
  hosted_zone_id = aws_route53_key_signing_key.main.hosted_zone_id
}

# 4. (Opzionale) Delegazione automatica se il dominio è registrato su Route 53
# Questo evita di dover inserire manualmente il record DS
resource "aws_route53domains_registered_domain" "main" {
  domain_name = "lysz210.me"

  # Inseriamo i Name Servers generati dalla zona creata in dns.tf
  dynamic "name_server" {
    for_each = aws_route53_zone.main.name_servers
    content {
      name = name_server.value
    }
  }
}