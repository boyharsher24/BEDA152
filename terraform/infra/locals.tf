locals {
  prefix       = "${var.application_name}-${var.environment_name}"
  cluster_name = "eks-${local.prefix}" # used by BOTH aws_eks_cluster and its log group name

  # Two AZs is the EKS minimum.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  cluster_subnet_ids = concat(
    [for s in aws_subnet.private : s.id],
    [for s in aws_subnet.public : s.id],
  )

  # TODO (Task 2): repository_list = ["raskur"] and a map built with a for expression
  #   -> see book "Container registry"
}
