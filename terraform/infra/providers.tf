provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      application = var.application_name
      environment = var.environment_name
      managed_by  = "terraform"
      episode     = "eks-docker-raskur"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
