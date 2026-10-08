# TASK 7 (cont.) - namespace + service account  (book: "Namespace", "Service account")
#
# TODO: kubernetes_namespace_v1 "main"   (name = var.k8s_namespace, label name=...)
# TODO: kubernetes_service_account_v1 "workload_identity"
#       - name/namespace MUST match what the IAM trust policy in infra expects
#       - annotation "eks.amazonaws.com/role-arn" = var.workload_identity_role
#       - reference the namespace via kubernetes_namespace_v1.main.metadata[0].name so
#         Terraform orders creation correctly (book hardcodes var.k8s_namespace - why is
#         referencing the resource better?)
