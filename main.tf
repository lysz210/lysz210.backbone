resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Fingerprint per GitHub (standard)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

module "lysz210_host" {
  source = "./modules/host"

  app_name            = "lysz210_host"
  domain_name         = "lysz210.me"
  github_owner        = "lysz210"
  github_repo         = "lysz210.host"
  aws_oidc_arn        = aws_iam_openid_connect_provider.github.arn
  aws_route53_zone_id = aws_route53_zone.main.zone_id
  aws_cert_arn        = aws_acm_certificate.wildcard.arn
}

module "lysz210_cv" {
  source = "./modules/cv"

  app_name            = "lysz210_cv"
  domain_name         = "cv.lysz210.me"
  github_owner        = "lysz210"
  github_repo         = "lysz210.cv"
  aws_oidc_arn        = aws_iam_openid_connect_provider.github.arn
  aws_route53_zone_id = aws_route53_zone.main.zone_id
  aws_cert_arn        = aws_acm_certificate.wildcard.arn
}