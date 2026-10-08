# These outputs are the hand-off to the terraform/k8s workspace (Fig 8.12).
# Uncomment / add as you finish each task.

# output "eks_cluster_name"        { value = aws_eks_cluster.main.name }
# output "ecr_repository_url"      { value = aws_ecr_repository.main["raskur"].repository_url }
# output "workload_identity_role"  { value = aws_iam_role.workload_identity.arn }
# output "secret_name"             { value = aws_secretsmanager_secret.app_secret.name }

output "vpc_id" {
  value = aws_vpc.main.id
}
