# TASK 9 - Secrets Store CSI driver + AWS provider + SecretProviderClass
# (book: "Secrets store CSI driver", "Secret provider class")
#
# TODO: helm_release "csi_secrets_store"  chart secrets-store-csi-driver,
#       repo https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts,
#       namespace kube-system, set syncSecret.enabled = true
# TODO: helm_release "aws_secrets_provider" chart secrets-store-csi-driver-provider-aws,
#       repo https://aws.github.io/secrets-store-csi-driver-provider-aws, kube-system
# TODO: kubernetes_manifest "secret_provider_class"
#       apiVersion secrets-store.csi.x-k8s.io/v1, kind SecretProviderClass
#       parameters.objects = yamlencode([{ objectName = <secret name>, objectType = "secretsmanager",
#                                           objectVersionLabel = "AWSCURRENT" }])
#       secretObjects -> Opaque k8s secret with the same name/key
#       (workload identity: serviceAccount is used by the POD, not by this resource)
#
# KNOWN TRAP: kubernetes_manifest validates against the cluster API at PLAN time, so the
# CRD must already exist. Fix: depends_on helm releases AND apply in two passes:
#   terraform apply -target=helm_release.csi_secrets_store -target=helm_release.aws_secrets_provider
#   terraform apply
# (same flavour of problem as the book's targeted apply on random_shuffle.az)
#
# Add a variable "secret_name" (output of infra) when you get here.
