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
