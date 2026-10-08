# TASK 5a - IRSA / Workload Identity  (book: "Workload identity")
#
# TODO: data tls_certificate "container_cluster_oidc"
#       url = aws_eks_cluster.main.identity[0].oidc[0].issuer
# TODO: aws_iam_openid_connect_provider "container_cluster_oidc"
#       client_id_list ["sts.amazonaws.com"], thumbprint from the tls data source
# TODO: data aws_iam_policy_document "workload_identity_assume_role_policy"
#       action sts:AssumeRoleWithWebIdentity, principal type Federated = provider ARN,
#       condition StringEquals "<issuer-without-https>:sub" =
#       "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
#       hint: replace(url, "https://", "")
# TODO: aws_iam_role "workload_identity"



data "tls_certificate" "container_cluster_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}


resource "aws_iam_openid_connect_provider" "container_cluster_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.container_cluster_oidc.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.container_cluster_oidc.url
}


data "aws_iam_policy_document" "workload_identity_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.container_cluster_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.container_cluster_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"]
    }
  }
}


resource "aws_iam_role" "workload_identity" {
  name               = "${local.prefix}-workload-identity"
  assume_role_policy = data.aws_iam_policy_document.workload_identity_assume_role_policy.json
}

