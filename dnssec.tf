# 1. Chiave KMS per la firma DNSSEC ($1.00/mese)
resource "aws_kms_key" "dnssec" {
  provider                 = aws.us_east_1
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  description              = "KMS Key for Backbone DNSSEC - lysz210.name"

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
  name                       = "backbone-ksk"
}

# 3. Abilitazione della firma sulla zona
resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on     = [aws_route53_key_signing_key.main]
  hosted_zone_id = aws_route53_key_signing_key.main.hosted_zone_id
}

# 4. (Opzionale) Delegazione automatica se il dominio è registrato su Route 53
# Questo evita di dover inserire manualmente il record DS
resource "aws_route53domains_registered_domain" "main" {
  domain_name = "lysz210.name"

  # Inseriamo i Name Servers generati dalla zona creata in dns.tf
  dynamic "name_server" {
    for_each = aws_route53_zone.main.name_servers
    content {
      name = name_server.value
    }
  }
}