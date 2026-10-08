# TASK 8 - deploy raskur  (book: "Deployment", "Service", "ConfigMap")
#
# NOTE the raskur Dockerfile listens on 8000 (the book's app used 5000) - everywhere the
# book says 5000, use 8000.
#
# TODO: kubernetes_config_map_v1 "web_app"  (data: APP_ENV = var.environment_name)
# TODO: kubernetes_deployment_v1 "web_app"
#       - replicas = var.replicas, labels app = local.app_name
#       - service_account_name from the service account RESOURCE
#       - container: image = local.image, port 8000, env_from config map
#       - readiness_probe + liveness_probe: http_get path "/" port 8000   (not in the book,
#         but without a readiness probe the NLB sends traffic to pods that aren't up)
#       - resources requests/limits (t3.small nodes are tiny)
#       - once Task 9 is done: env var DB_CONNECTION_STRING from secret_key_ref and a
#         csi volume (driver secrets-store.csi.k8s.io, read_only, volumeAttributes
#         secretProviderClass = <name>) - secretObjects are ONLY created when a pod mounts it
# TODO: kubernetes_service_v1 "web_app"  ClusterIP, port 80 -> target_port 8000, selector app label
