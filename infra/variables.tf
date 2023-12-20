variable "name" {
  type    = string
  default = "synonyms"

  description = "Name of the application"
}

variable "env" {
  type    = string
  default = "prod"

  description = "What type enviroment we are in dev, prod, stage"
}

variable "aws_account_id" {
  type        = string
  description = "The ID of your AWS account"
  default     = "275567994947"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "The aws_account_id must be a 12 digit number."
  }
}

variable "domain" {
  type    = string
  default = "synonyms.castrojonsson.se"

  description = "the domain used for the frontend"
}

variable "hosted_zone_id" {
  type    = string
  default = "Z06167743PXL34GPE1XSN"

  description = "The ID of the route 53 hosted zone for our domain"
}

variable "github_repo" {
  type        = string
  description = "The name of the github repo that will run the gh action"
  default     = "synonyms"

  validation {
    condition     = var.github_repo != ""
    error_message = "The github_repo cannot be an empty string."
  }
}

variable "github_organization" {
  type        = string
  description = "The name of the github organization"
  default     = "bejo-geshdo"

  validation {
    condition     = var.github_organization != ""
    error_message = "The github_organization cannot be an empty string."
  }
}

variable "github_branch" {
  type        = string
  description = "The name of the branch that will run the gh action"
  default     = "main"

  validation {
    condition     = var.github_branch != ""
    error_message = "The github_branch cannot be an empty string."
  }
}