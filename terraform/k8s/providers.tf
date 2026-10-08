# TASK 7 - wire the kubernetes + helm providers to the EKS cluster created by infra.
# Book: "Provider setup".
#
# TODO: data "aws_eks_cluster" "cluster"       { name = var.eks_cluster_name }
# TODO: data "aws_eks_cluster_auth" "cluster"  { name = var.eks_cluster_name }
# TODO: provider "kubernetes" { host, cluster_ca_certificate (base64decode!), token }
# TODO: provider "helm" { kubernetes { ...same three... } }
#
# Book gotchas to fix as you go:
#  - the book's helm snippet references data.aws_eks_cluster.main but the data source is
#    named "cluster" -> be consistent
#  - `load_config_file` was removed in kubernetes provider 2.x - do NOT use it
#
# This works only if you ran `terraform apply` in terraform/infra first (the
# cluster must exist at plan time).

provider "aws" {
  region = var.primary_region
}

data "aws_caller_identity" "current" {}

locals {
  app_name           = "${var.application_name}-${var.environment_name}"
  container_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.primary_region}.amazonaws.com"
  # TODO (Task 8): image = "${local.container_registry}/${var.ecr_repository_name}:${var.image_tag}"
}
