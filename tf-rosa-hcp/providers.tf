terraform {
  required_providers {
    rhcs = {
      source = "terraform-redhat/rhcs"
      version = ">= 1.6.2-prerelease.1"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

provider "rhcs" {
  token = var.token
}

provider "aws" {
  region = var.region
}