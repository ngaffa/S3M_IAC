terraform {
  backend "remote" {
    organization = "gafa"

    workspaces {
      name = "s3m-pattern"
    }
  }
}

provider "aws" {
  region = var.region
}
















