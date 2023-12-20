# --- ECR ---

#Sets up or container registry
resource "aws_ecr_repository" "app" {
  name                 = "${var.name}-${var.env}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# --- Github Action IAM ---

#Creates an IAM role with a policy that gives it access to ECR

data "aws_iam_policy_document" "github_action_ECR_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
  }
}

resource "aws_iam_role" "github_action_ECR_role" {
  name_prefix        = "${var.name}-${var.env}-gh-actions-ECR-role"
  assume_role_policy = data.aws_iam_policy_document.github_action_ECR_doc.json
}


data "aws_iam_policy_document" "github_action_ECR_policy_doc" {
  statement {
    #TODO lock down action to only put or the same as AmazonEC2ContainerRegistryPowerUser
    actions   = ["ecr:*"]
    effect    = "Allow"
    resources = aws_ecr_repository.app.arn
  }
}

resource "aws_iam_policy" "github_action_ECR_policy" {
  name_prefix = "${var.name}-${var.env}-gh-actions-ECR-policy"
  description = "Used to give github actions access to the ${aws_ecr_repository.app.name}"
  policy      = data.aws_iam_policy_document.github_action_ECR_policy_doc
}

resource "aws_iam_role_policy_attachment" "github_action_ECR_policy" {
  role       = aws_iam_role.github_action_ECR_role.name
  policy_arn = aws_iam_policy.github_action_ECR_policy.arn
}


output "demo_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "gh_actions_role_arn" {
  value = aws_iam_role.github_action_ECR_role.arn
}

