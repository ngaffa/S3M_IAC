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
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}
















