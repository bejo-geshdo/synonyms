terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "5.31.0" }
  }
  backend "s3" {
    bucket = "tf-state-275567994947"
    key = "synonyms-state"
    region = "eu-central-1"
    #Added for state locking 
    dynamodb_table = "tf-state-275567994947"
  }
}

provider "aws" {
  //profile = "bejo"
  region  = "eu-central-1"
}

