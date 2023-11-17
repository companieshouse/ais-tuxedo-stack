terraform {
  required_version = ">= 1.3"

  backend "s3" {}

  required_providers {
    aws = {
      version = ">= 5.0, < 6.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}
