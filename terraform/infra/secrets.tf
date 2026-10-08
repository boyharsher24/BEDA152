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
