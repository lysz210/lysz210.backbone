resource "aws_s3_bucket" "lysz210_host_storage" {
  bucket = "lysz210-host-storage" # Nome univoco
}

resource "aws_s3_bucket_public_access_block" "lysz210_host_storage" {
  bucket                  = aws_s3_bucket.lysz210_host_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "lysz210_host_oac" {
  name                              = "lysz210-host-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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
resource "aws_cloudfront_function" "rewrite_uri" {
  name    = "rewrite-uri"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Se l'URI non ha estensione (es. non è .js, .css, .png), aggiungi index.html
    if (!uri.includes('.')) {
        if (uri.endsWith('/')) {
            request.uri += 'index.html';
        } else {
            request.uri += '/index.html';
        }
    }
    
    return request;
}
EOF
}
resource "aws_cloudfront_distribution" "lysz210_host_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["${var.domain_name}"]

  origin {
    domain_name              = aws_s3_bucket.lysz210_host_storage.bucket_regional_domain_name
    origin_id                = "S3-Lysz210-Host"
    origin_access_control_id = aws_cloudfront_origin_access_control.lysz210_host_oac.id
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.static_paths
    content {
      path_pattern     = ordered_cache_behavior.value
      target_origin_id = "S3-Lysz210-Host"

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
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Lysz210-Host"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
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
  bucket = aws_s3_bucket.lysz210_host_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.lysz210_host_storage.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.lysz210_host_distribution.arn
        }
      }
    }]
  })
}


resource "aws_route53_record" "lysz210_host_alias" {
  zone_id = var.aws_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lysz210_host_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.lysz210_host_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}