
# --- S3 ---
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${var.name}-${var.env}-frontend-${var.aws_account_id}"
}

resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "private"
}

resource "aws_cloudfront_origin_access_control" "frontend_bucket_oac" {
  name                              = "s3-cloudfront-oac"
  description                       = "Grant cloudfront access to s3 bucket ${aws_s3_bucket.frontend_bucket.id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- CloudFront ---

locals {
  s3_origin_id = "${var.name}-${var.env}-S3Origin"
}

resource "aws_cloudfront_distribution" "cloud_front" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_bucket_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  comment             = "The CF for ${var.name}-${var.env}"
  default_root_object = "index.html"
  #Makes it so TF does not wait for CF to be fully deployed
  wait_for_deployment = false

  #TODO Add Route 53
  #aliases = ["synonyms.castrojonsson.se"]

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  is_ipv6_enabled = true
  http_version    = "http2and3"
  #Runns the CF only in EU an NA
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      #locations        = ["SE", "DK", "NO", "FI"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    #TODO change cache time for prod
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }
}

# --- Github actions IAM ---

data "aws_iam_policy_document" "github_action_S3_doc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:bejo-geshdo/synonyms:ref:refs/heads/dev", "repo:bejo-geshdo/synonyms:ref:refs/heads/main",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "github_action_S3_role" {
  name_prefix        = "${var.name}-${var.env}-gh-actions-S3-role"
  assume_role_policy = data.aws_iam_policy_document.github_action_ECR_doc.json
}

data "aws_iam_policy_document" "github_action_ECR_policy_doc" {
  statement {
    #TODO lock down action so it can not delete the bucket
    actions   = ["s3:*"]
    effect    = "Allow"
    resources = [aws_s3_bucket.frontend_bucket.arn]
  }

  #Allows the role to empty the cache in Cloudfront
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    effect    = "Allow"
    resources = [aws_cloudfront_distribution.cloud_front.arn]
  }
}

output "frontend_s3_bucket_name" {
  value = aws_s3_bucket.frontend_bucket.id
}
output "cloud_front_url" {
  value = aws_cloudfront_distribution.cloud_front.domain_name
}

output "cloud_front_ID" {
  value = aws_cloudfront_distribution.cloud_front.id
}

output "gh_actions_S3_role_arn" {
  value = aws_iam_role.github_action_S3_role
}

