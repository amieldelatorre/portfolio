resource "aws_s3_bucket" "this" {
  bucket = var.content_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "AllowPublicAccessThroughCloudfrontOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
      ]
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

resource "aws_acm_certificate" "this" {
  provider                  = aws.usea1
  domain_name               = aws_route53_zone.this.name
  subject_alternative_names = ["www.${aws_route53_zone.this.name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "this" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.usea1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.this : record.fqdn]
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.this.id
  name    = aws_route53_zone.this.name
  type    = "A"

  alias {
    name                    = aws_cloudfront_distribution.this.domain_name
    zone_id                 = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health  = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.this.id
  name    = "www.${aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                    = aws_route53_zone.this.name
    zone_id                 = aws_route53_zone.this.id
    evaluate_target_health  = false
  }
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "Only Cloudfront access"
  description                       = "Allow for only cloudfront to be the origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  aliases = [
    aws_s3_bucket.this.id,
    aws_route53_record.www.name
  ]

  enabled             = true
  default_root_object = aws_s3_bucket_website_configuration.this.index_document[0].suffix

  origin {
    domain_name               = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                 = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id  = aws_cloudfront_origin_access_control.this.id
  }
  
  default_cache_behavior {
    allowed_methods         = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = aws_s3_bucket.this.bucket_regional_domain_name
    compress                = true
    cache_policy_id         = data.aws_cloudfront_cache_policy.this.id
    viewer_protocol_policy  = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      locations         = []
      restriction_type  = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method  = "sni-only"
  }

}