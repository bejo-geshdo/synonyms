provider "aws" {
  //profile = "bejo"
  region = "eu-central-1"
}

# Create Bucket to store TF

resource "aws_s3_bucket" "tf-state" {
  #TODO Get ID from env
  bucket = "tf-state-${var.aws_account_id}"


  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create a DDB table to lock state

resource "aws_dynamodb_table" "tf_state_lock" {
  name           = "app-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create OIDC to Github

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

# Create IAM role for Terraform to be used by github

resource "aws_iam_role" "github_actions_role" {
  assume_role_policy = jsonencode(({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" : ["repo:${var.github_organization}/${var.github_repo}:ref:refs/heads/main", "repo:${var.github_organization}/${var.github_repo}:ref:refs/heads/dev"]
          }
        }
      }
    ]
  }))
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}