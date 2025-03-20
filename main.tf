provider "aws" {
  region = var.region
}

## Data
data "aws_caller_identity" "current" {}

# Locals
locals {
  account_id = data.aws_caller_identity.current.account_id
}
