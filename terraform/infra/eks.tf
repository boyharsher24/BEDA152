# TASK 3 - EKS control plane  (book: "Kubernetes cluster" + "Logging and monitoring")
#
# TODO: data aws_iam_policy_document "container_cluster_assume_role"  (eks.amazonaws.com)
# TODO: aws_iam_role "container_cluster"
# TODO: attach AmazonEKSClusterPolicy and AmazonEKSVPCResourceController
#       (hint: for_each over a set of ARNs instead of copy-paste; ARNs look like
#        arn:aws:iam::aws:policy/<Name>)
# TODO: aws_cloudwatch_log_group "container_cluster"
#       name MUST be "/aws/eks/${local.cluster_name}/cluster", retention 7
# TODO: aws_eks_cluster "main"
#       - name = local.cluster_name, role_arn from your role
#       - vpc_config: both security groups from network.tf, subnet_ids = local.cluster_subnet_ids,
#         endpoint_public_access = true, endpoint_private_access = true
#       - enabled_cluster_log_types = ["api", "audit"]
#       - depends_on: policy attachments + log group (no attribute reference links them!)
#
# Cost note: the control plane is ~$0.10/h as soon as you apply.
