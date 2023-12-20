variable "aws_account_id" {
  type        = string
  description = "The ID of your AWS account"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "The aws_account_id must be a 12 digit number."
  }
}

variable "github_repo" {
  type        = string
  description = "The name of the github repo that will run the gh action"

  validation {
    condition     = var.github_repo != ""
    error_message = "The github_repo cannot be an empty string."
  }
}

variable "github_organization" {
  type        = string
  description = "The name of the github organization"

  validation {
    condition     = var.github_organization != ""
    error_message = "The github_organization cannot be an empty string."
  }
}

variable "github_branch" {
  type        = string
  description = "The name of the branch that will run the gh action"

  validation {
    condition     = var.github_branch != ""
    error_message = "The github_branch cannot be an empty string."
  }
}