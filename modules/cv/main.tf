resource "aws_s3_bucket" "lysz210_cv_storage" {
  bucket = "lysz210-cv-storage" # Nome univoco
}

resource "aws_s3_bucket_public_access_block" "lysz210_cv_storage" {
  bucket                  = aws_s3_bucket.lysz210_cv_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "lysz210_cv_oac" {
  name                              = "lysz210-cv-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_iam_role" "lambda_role" {
  name = "cv_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "dummy_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/dummy_lambda.zip"
  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: 'Loading...' });"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "nuxt_server" {
  function_name = "lysz210CvServer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs24.x"
  filename      = data.archive_file.dummy_lambda_zip.output_path
  timeout       = 30

  # Ignoriamo le modifiche al codice fatte da GitHub Actions
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function_url" "nuxt_url" {
  function_name      = aws_lambda_function.nuxt_server.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

locals {
  static_paths = [
    "/favicon.ico",
    "/_nuxt/*"
  ]
}
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewerExceptHostHeader"
}
resource "aws_cloudfront_distribution" "lysz210_cv_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["${var.domain_name}"]

  # --- ORIGIN 1: Lambda (Server Side Rendering) ---
  origin {
    domain_name = split("/", aws_lambda_function_url.nuxt_url.function_url)[2]
    origin_id   = "Lambda-lysz210-cv"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  origin {
    domain_name              = aws_s3_bucket.lysz210_cv_storage.bucket_regional_domain_name
    origin_id                = "S3-lysz210-cv"
    origin_access_control_id = aws_cloudfront_origin_access_control.lysz210_cv_oac.id
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "Lambda-lysz210-cv" # Deve corrispondere all'ID nel blocco origin

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"

    # Fondamentale: Disabilita la cache per le chiamate API
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }
  dynamic "ordered_cache_behavior" {
    for_each = local.static_paths
    content {
      path_pattern     = ordered_cache_behavior.value
      target_origin_id = "S3-lysz210-cv"

      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]

      forwarded_values {
        query_string = false
        cookies { forward = "none" }
      }

      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    }
  }

  default_cache_behavior {
    target_origin_id = "Lambda-lysz210-cv"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Importante: Per SSR servono i Query Strings e spesso i Cookies
    forwarded_values {
      query_string = true
      cookies { forward = "all" }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.aws_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.lysz210_cv_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.lysz210_cv_storage.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.lysz210_cv_distribution.arn
        }
      }
    }]
  })
}


resource "aws_route53_record" "lysz210_cv_alias" {
  zone_id = var.aws_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lysz210_cv_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.lysz210_cv_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}