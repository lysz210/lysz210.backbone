# 1. Hosted Zone
resource "aws_route53_zone" "main" {
  name          = "lysz210.me"
  comment       = "Managed by Terraform - Core Infrastructure"
  force_destroy = false
}

# 2. Keybase Verification
resource "aws_route53_record" "keybase_verification" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lysz210.me"
  type    = "TXT"
  ttl     = 172800
  records = ["keybase-site-verification=CSIcI9LwdT2ZCbeyPqVAEIL0Z65TSaByfWoVkeku5Gc"]
}

# 3. Certificato Wildcard
resource "aws_acm_certificate" "wildcard" {
  provider                  = aws.us_east_1
  domain_name               = "*.lysz210.me"
  subject_alternative_names = ["lysz210.me"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 4. Validazione Certificato
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

# 5. Parametri SSM (Con contesto lysz210)
resource "aws_ssm_parameter" "zone_id" {
  name  = "/lysz210/infra/route53_zone_id"
  type  = "String"
  value = aws_route53_zone.main.zone_id
}

resource "aws_ssm_parameter" "wildcard_cert_arn" {
  name  = "/lysz210/infra/wildcard_cert_arn"
  type  = "String"
  value = aws_acm_certificate.wildcard.arn
}

# --- DNSSEC SECTION ---

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
        Principal = { AWS = "*" }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "api-dnssec.route53.amazonaws.com" # FIX: Nome servizio corretto
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 Create Grant" # FIX: Necessario per DNSSEC
        Effect = "Allow"
        Principal = {
          Service = "api-dnssec.route53.amazonaws.com"
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" = "true" }
        }
      }
    ]
  })
}

resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "lysz210-ksk"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on     = [aws_route53_key_signing_key.main]
  hosted_zone_id = aws_route53_key_signing_key.main.hosted_zone_id
}