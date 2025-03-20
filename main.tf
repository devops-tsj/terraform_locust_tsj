provider "aws" {
  region = var.region
  role = "arn:aws:iam::970863514724:role/service-role/codebuild-locust_tsj_apply-service-role"
}

## Data
data "aws_caller_identity" "current" {}

# Locals
locals {
  account_id = data.aws_caller_identity.current.account_id
}
