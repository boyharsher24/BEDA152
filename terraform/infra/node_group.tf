# TASK 4 - Worker nodes  (book: aws_eks_node_group + node IAM role)
#
# TODO: assume-role policy document, principal ec2.amazonaws.com (sid "EKSNodeAssumeRole")
# TODO: aws_iam_role "container_node_group"
# TODO: attach the FOUR mandatory policies:
#         AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy,
#         AmazonEC2ContainerRegistryReadOnly, CloudWatchAgentServerPolicy
#       (the 2nd and 3rd are what let nodes pull the raskur image from ECR)
# TODO: aws_eks_node_group "main": node_group_name "ng-user",
#       subnets = PRIVATE subnets only (the book passes local.cluster_subnet_ids;
#       think about whether that matches Fig 8.3 - hint: node_group needs private ones),
#       scaling desired=2 min=1 max=3 (lab-sized, book uses 3/1/4),
#       ami_type = var.node_image_type, instance_types = [var.node_size]
#       depends_on = all four attachments
#
# BONUS (optional, book section "Load balancing"): extra policy so the cluster can
# manage ELBs (elasticloadbalancing:*, ec2:Describe*...) attached to the node role.




data "aws_iam_policy_document" "container_node_group" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "container_node_group" {
  name               = "${local.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.container_node_group.json
}

resource "aws_iam_role_policy_attachment" "container_node_group" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",          # join the cluster
    "AmazonEKS_CNI_Policy",               # give pods IP addresses
    "AmazonEC2ContainerRegistryReadOnly", # pull images from ECR
    "CloudWatchAgentServerPolicy",        # ship metrics and logs
  ])
  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
  role       = aws_iam_role.container_node_group.name
}


resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ng-user"
  node_role_arn   = aws_iam_role.container_node_group.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  ami_type       = var.node_image_type
  instance_types = [var.node_size]

  depends_on = [
    aws_iam_role_policy_attachment.container_node_group,
  ]
}

