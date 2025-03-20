terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "tsj-backend-tfstates"
    key    = "terraform.tfstate"
    region = "us-east-1"
    
  }
}


provider "aws" {
  region = var.region
}
