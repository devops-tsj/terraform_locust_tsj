provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.switch_role_arn
  }
}

## Data
data "aws_caller_identity" "current" {}

# Locals
locals {
  account_id = data.aws_caller_identity.current.account_id
}