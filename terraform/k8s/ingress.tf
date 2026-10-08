# TASK 10 - NGINX ingress controller -> AWS NLB  (book: "Ingress")
#
# TODO: helm_release "ingress"  namespace ingress-nginx, create_namespace = true
#
#   BOOK vs REALITY: the book uses bitnami/nginx-ingress-controller. Bitnami moved its free
#   charts to a "legacy" repo in 2025, so that repo is unreliable. Use the community chart:
#       repository = "https://kubernetes.github.io/ingress-nginx"
#       chart      = "ingress-nginx"
#   (NB: the ingress-nginx project was announced as retiring in Nov 2025 and the repo was archived in March 2026 - fine for a lab,
#    and a nice discussion point: what would you move to? Gateway API / AWS LB Controller.)
#
#   Service annotation to get an NLB (the key contains dots -> escape them in `set`):
#       controller.service.type = LoadBalancer
#       controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type = nlb
#   (the book's `service.annotations` as one string would NOT work for this chart - why?)
#
# TODO: kubernetes_ingress_v1 "ingress"
#       - spec.ingress_class_name = "nginx"  (the kubernetes.io/ingress.class annotation in
#         the book is deprecated)
#       - rule / http / path "/" Prefix -> backend service web_app port 80
#       - depends_on: service + helm_release.ingress
