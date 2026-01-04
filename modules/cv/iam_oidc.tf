resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-lysz210-cv-deployer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.aws_oidc_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # Qui limitiamo l'accesso SOLO alla tua repository specifica
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_owner}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# 3. Permessi del Ruolo (S3 e CloudFront)
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "lysz210-cv-deploy-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:ListBucket", "s3:DeleteObject", "s3:GetObject"]
        Resource = [
          aws_s3_bucket.lysz210_cv_storage.arn,
          "${aws_s3_bucket.lysz210_cv_storage.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = [aws_cloudfront_distribution.lysz210_cv_distribution.arn]
      }
    ]
  })
}