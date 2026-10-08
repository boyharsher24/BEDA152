# TASK 5b - Secrets Manager + least-privilege access  (book: "Secrets management")
#
# TODO: random_password "app_secret" (length 24, special = false)
# TODO: aws_secretsmanager_secret "app_secret"
#       name = "${local.prefix}-connection-string"  <- the prefix IS the naming convention
#       recovery_window_in_days = 0   (lab only! lets terraform destroy + re-apply reuse the name)
# TODO: aws_secretsmanager_secret_version
# TODO: policy document: secretsmanager:GetSecretValue + DescribeSecret.
#       The book scopes to ".../secret:*". Do BETTER: scope to
#       "arn:aws:secretsmanager:<region>:<account>:secret:${local.prefix}-*"
#       (use data.aws_caller_identity.current.account_id)
# TODO: aws_iam_role_policy attaching it to the workload_identity role



resource "random_password" "app_secret" {
  length  = 24
  special = false
}


resource "aws_secretsmanager_secret" "app_secret" {
  name                    = "${local.prefix}-connection-string"
  description             = "raskur connection string (lab)"
  recovery_window_in_days = 0 # lab only: allows destroy then re-apply with the same name
}


resource "aws_secretsmanager_secret_version" "app_secret" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = random_password.app_secret.result
}


data "aws_iam_policy_document" "workload_identity_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:${local.prefix}-*"
    ]
  }
}


resource "aws_iam_role_policy" "workload_identity" {
  name   = "${local.prefix}-workload-identity-secrets"
  role   = aws_iam_role.workload_identity.id
  policy = data.aws_iam_policy_document.workload_identity_policy.json
}
